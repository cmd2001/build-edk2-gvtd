gop_bin_dir="./gop"
docker_image_name="ubuntu:ovmf.22.04"
tmp_dir="./build_gop_tmp"
product_dir="./product"
product_filename="B660.rom"

if [ ! -d "${gop_bin_dir}" ]; then
    mkdir ${gop_bin_dir}
    echo "Copy IntelGopDriver.efi to ${gop_bin_dir}"
    exit
fi

if [ ! -f "${gop_bin_dir}/IntelGopDriver.efi" ]; then
    echo "Copy IntelGopDriver.efi to ${gop_bin_dir}"
    exit
fi

efi_dir="./edk2/Build/OvmfX64/DEBUG_GCC5/X64"
if [ ! -f "${efi_dir}/PlatformGOPPolicy.efi" ]; then
    echo "Run build_ovmf.sh first"
    exit
fi
if [ ! -f "${efi_dir}/IgdAssignmentDxe.efi" ]; then
    echo "Run build_ovmf.sh first"
    exit
fi

if [ ! -d "${tmp_dir}" ]; then
    mkdir ${tmp_dir}
fi

cp ${gop_bin_dir}/IntelGopDriver.efi ${tmp_dir}/
cp ${efi_dir}/PlatformGOPPolicy.efi  ${tmp_dir}/
cp ${efi_dir}/IgdAssignmentDxe.efi ${tmp_dir}/

docker run \
    -ti \
    --rm \
    -w $PWD/edk2 \
    -v $PWD:$PWD \
    --security-opt label=disable \
    ${docker_image_name} \
    /bin/bash -c "source edksetup.sh && cd ../${tmp_dir} && pwd && EfiRom -f 0x8086 -i 0xffff -e ./IntelGopDriver.efi ./IgdAssignmentDxe.efi ./PlatformGOPPolicy.efi -o ${product_filename}"
cp ${tmp_dir}/${product_filename} ${product_dir}/${product_filename} 

rm -r ${tmp_dir}