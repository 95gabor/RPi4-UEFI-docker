#!/bin/bash

set -x

export WORKSPACE=$PWD
export PACKAGES_PATH=$WORKSPACE/edk2:$WORKSPACE/edk2-platforms:$WORKSPACE/edk2-non-osi
export BUILD_FLAGS="-D SECURE_BOOT_ENABLE=TRUE -D INCLUDE_TFTP_COMMAND=TRUE -D NETWORK_ISCSI_ENABLE=TRUE -D SMC_PCI_SUPPORT=1"
export TLS_DISABLE_FLAGS="-D NETWORK_TLS_ENABLE=FALSE -D NETWORK_ALLOW_HTTP_CONNECTIONS=TRUE"
export DEFAULT_KEYS="-D DEFAULT_KEYS=TRUE -D PK_DEFAULT_FILE=$WORKSPACE/keys/pk.cer -D KEK_DEFAULT_FILE1=$WORKSPACE/keys/ms_kek1.cer -D KEK_DEFAULT_FILE2=$WORKSPACE/keys/ms_kek2.cer -D DB_DEFAULT_FILE1=$WORKSPACE/keys/ms_db1.cer -D DB_DEFAULT_FILE2=$WORKSPACE/keys/ms_db2.cer -D DB_DEFAULT_FILE3=$WORKSPACE/keys/ms_db3.cer -D DB_DEFAULT_FILE4=$WORKSPACE/keys/ms_db4.cer -D DBX_DEFAULT_FILE1=$WORKSPACE/keys/arm64_dbx.bin"
# EDK2's 'build' command doesn't play nice with spaces in environmnent variables, so we can't move the PCDs there...
source edk2/edksetup.sh
for BUILD_TYPE in DEBUG RELEASE; do
    build -a ${ARCH} -t ${COMPILER} -b $BUILD_TYPE -p edk2-platforms/Platform/RaspberryPi/RPi4/RPi4.dsc --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVendor=L"${PROJECT_URL}" --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVersionString=L"UEFI Firmware" ${BUILD_FLAGS} ${DEFAULT_KEYS} ${TLS_DISABLE_FLAGS}
    TLS_DISABLE_FLAGS=""
done
