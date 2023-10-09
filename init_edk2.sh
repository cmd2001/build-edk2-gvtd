git submodule update --init --recursive
cd edk2
git apply --check ../0001-OvmfPkg-Add-OpRegion-and-VBT-header-definition.patch
git apply ../0001-OvmfPkg-Add-OpRegion-and-VBT-header-definition.patch
git apply --check ../0002-OvmfPkg-add-IgdAssignmentDxe.patch
git apply ../0002-OvmfPkg-add-IgdAssignmentDxe.patch
git apply --check ../0003-OvmfPkg-add-Platform-GOP-Policy.patch
git apply ../0003-OvmfPkg-add-Platform-GOP-Policy.patch
git apply --check ../0004-OvmfPkg-PlatformGopPolicy-Add-OpRegion-2.1-support.patch
git apply ../0004-OvmfPkg-PlatformGopPolicy-Add-OpRegion-2.1-support.patch
git apply --check ../0005-OvmfPkg-PlatformPei-Reserve-IGD-Stolen-in-E820.patch
git apply ../0005-OvmfPkg-PlatformPei-Reserve-IGD-Stolen-in-E820.patch