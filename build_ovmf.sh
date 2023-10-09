#!/bin/bash
# Copyright (C) 2021 Intel Corporation.
# SPDX-License-Identifier: BSD-3-Clause
#
# PREREQUISITES:
# 1) Get your specific "IntelGopDriver.efi" and "Vbt.bin"
#    from your BIOS vender
# 2) Install docker
# 3) If you are working behind proxy, create a file named
#    "proxy.conf" in ${your_working_directory} with
#    configurations like below:
#    Acquire::http::Proxy "http://x.y.z:port1";
#    Acquire::https::Proxy "https://x.y.z:port2";
#    Acquire::ftp::Proxy "ftp://x.y.z:port3";
#
# HOWTO:
# 1) mkdir ${your_working_directory}
# 2) cd ${your_working_directory}
# 2) mkdir gop
# 3) cp /path/to/IntelGopDriver.efi /path/to/Vbt.bin gop
# 4) cp /path/to/build_ovmf.sh ${your_working_directory}
# 5) ./build_ovmf.sh
#
# OUTPUT: ${your_working_directory}/edk2/Build/OvmfX64/DEBUG_GCC5/FV/OVMF.fd
#
# For more information, ./build_ovmf.sh -h
#

product_dir="./product"
docker_image_name="ubuntu:ovmf.22.04"
proxy_conf="proxy.conf"

if [ ! -x "$(command -v docker)" ]; then
    echo "Install docker first:"
    exit
fi


if [ ! -f "${proxy_conf}" ]; then
    touch "${proxy_conf}"
fi

usage()
{
    echo "$0 [-v ver] [-i] [-s] [-h]"
    echo "  -i:     Delete the existing docker image ${docker_image_name} and re-create it"
    echo "  -I image size: image size in MB"
    echo "  -h:     Show this help"
    exit
}

re_download=0
re_create_image=0
image_size=4

while getopts "hisb:SI:" opt
do
    case "${opt}" in
        h)
            usage
            ;;
        i)
            re_create_image=1
            ;;
        s)
            re_download=1
            ;;
        I)
            image_size=${OPTARG}
            ;;
        ?)
            echo "${OPTARG}"
            ;;
    esac
done
shift $((OPTIND-1))

if [[ "${re_create_image}" -eq 1 ]]; then
    if [[ "$(docker images -q ${docker_image_name} 2> /dev/null)" != "" ]]; then
        echo "===================================================================="
        echo "Deleting the old Docker image ${docker_image_name}  ..."
        echo "===================================================================="
        docker image rm -f "${docker_image_name}"
        docker image rm -f "${docker_qemu_image_name}"
    fi
fi

if [[ "${re_download}" -eq 1 ]]; then
    echo "===================================================================="
    echo "Deleting the old edk2 source code ..."
    echo "===================================================================="
    rm -rf edk2
fi

create_edk2_workspace()
{
    echo "===================================================================="
    echo "Downloading edk2 source code ..."
    echo "===================================================================="

    return 0
}

create_docker_image()
{
    echo "===================================================================="
    echo "Creating Docker image ..."
    echo "===================================================================="
    docker build -t "${docker_image_name}" -f Dockerfile.ovmf .
}


if [[ "$(docker images -q ${docker_image_name} 2> /dev/null)" == "" ]]; then
    create_docker_image
fi
if [ ! -d edk2 ]; then
    create_edk2_workspace
    if [ $? -ne 0 ]; then
        echo "Download edk2 failed"
        exit
    fi
else
    cd edk2
fi

source edksetup.sh

sed -i "s:^ACTIVE_PLATFORM\s*=\s*\w*/\w*\.dsc*:ACTIVE_PLATFORM       = OvmfPkg/OvmfPkgX64.dsc:g" Conf/target.txt
sed -i "s:^TARGET_ARCH\s*=\s*\w*:TARGET_ARCH           = X64:g" Conf/target.txt
sed -i "s:^TOOL_CHAIN_TAG\s*=\s*\w*:TOOL_CHAIN_TAG        = GCC5:g" Conf/target.txt

cd ..

# OVMF_FLAGS="-DNETWORK_IP6_ENABLE -DNETWORK_HTTP_BOOT_ENABLE -DNETWORK_TLS_ENABLE -DTPM2_ENABLE"
OVMF_FLAGS="-DNETWORK_TLS_ENABLE -DNETWORK_IP6_ENABLE -DNETWORK_HTTP_BOOT_ENABLE -DNETWORK_ALLOW_HTTP_CONNECTIONS -DNETWORK_ISCSI_ENABLE"
OVMF_FLAGS="$OVMF_FLAGS -DPVSCSI_ENABLE -DMPT_SCSI_ENABLE -DLSI_SCSI_ENABLE"
OVMF_FLAGS="$OVMF_FLAGS -DTPM2_ENABLE"
OVMF_FLAGS="$OVMF_FLAGS -DFD_SIZE_${image_size}MB"
#OVMF_FLAGS="$OVMF_FLAGS -DDEBUG_ON_SERIAL_PORT=TRUE"

# build non-secure boot ovmf
docker run \
    -ti \
    --rm \
    -w $PWD/edk2 \
    -v $PWD:$PWD \
    --security-opt label=disable \
    ${docker_image_name} \
    /bin/bash -c "source edksetup.sh && make -C BaseTools && build $OVMF_FLAGS"

rm -rf ${product_dir}
mkdir ${product_dir}
cp ./edk2/Build/OvmfX64/DEBUG_GCC5/FV/OVMF_CODE.fd ${product_dir}/OVMF_CODE_${image_size}M.fd

# build secure boot ovmf
docker run \
    -ti \
    --rm \
    -w $PWD/edk2 \
    -v $PWD:$PWD \
    --security-opt label=enable \
    ${docker_image_name} \
    /bin/bash -c "source edksetup.sh && make -C BaseTools && build -DSECURE_BOOT_ENABLE $OVMF_FLAGS"
cp ./edk2/Build/OvmfX64/DEBUG_GCC5/FV/OVMF_CODE.fd ${product_dir}/OVMF_CODE_${image_size}M.secboot.fd