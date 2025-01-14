# Base image with Ubuntu
FROM ubuntu:22.04

# Maintainer information
LABEL maintainer="Gabor Pichner, Pete Batard <pete@akeo.ie>"
LABEL description="Dockerfile to build UEFI firmware for Raspberry Pi 4."

# Set environment variables
ENV PROJECT_URL=https://github.com/pftf/RPi4 \
    RPI_FIRMWARE_URL=https://github.com/raspberrypi/firmware/ \
    ARCH=AARCH64 \
    COMPILER=GCC5 \
    GCC5_AARCH64_PREFIX=aarch64-linux-gnu- \
    START_ELF_VERSION=master \
    DTB_VERSION=b49983637106e5fb33e2ae60d8c15a53187541e4 \
    DTBO_VERSION=master \
    RPi4_VERSION=v1.38

# Update and install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc-aarch64-linux-gnu \
    zip \
    curl \
    git \
    acpica-tools \
    openssl \
    ca-certificates \
    uuid-dev \
    python3 \
    python3-pip \
    python-is-python3 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*


# Clone repositories
WORKDIR /workspace

RUN git clone --branch $RPi4_VERSION https://github.com/pftf/RPi4 .

# fix missing git module
RUN git submodule update --init
RUN sed -i 's|https://github.com/Zeex/subhook.git|https://github.com/tianocore/edk2-subhook.git|' edk2/.gitmodules
RUN git submodule sync && git submodule update --init --recursive

# Build EDK2 BaseTools
RUN make -C edk2/BaseTools

# Set up Secure Boot default keys
RUN mkdir keys && \
    openssl req -new -x509 -newkey rsa:2048 -subj "/CN=Raspberry Pi Platform Key/" -keyout /dev/null -outform DER -out keys/pk.cer -days 7300 -nodes -sha256 && \
    curl -L https://go.microsoft.com/fwlink/?LinkId=321185 -o keys/ms_kek1.cer && \
    curl -L https://go.microsoft.com/fwlink/?linkid=2239775 -o keys/ms_kek2.cer && \
    curl -L https://go.microsoft.com/fwlink/?linkid=321192 -o keys/ms_db1.cer && \
    curl -L https://go.microsoft.com/fwlink/?linkid=321194 -o keys/ms_db2.cer && \
    curl -L https://go.microsoft.com/fwlink/?linkid=2239776 -o keys/ms_db3.cer && \
    curl -L https://go.microsoft.com/fwlink/?linkid=2239872 -o keys/ms_db4.cer && \
    curl -L https://uefi.org/sites/default/files/resources/dbxupdate_arm64.bin -o keys/arm64_dbx.bin

# Customization
# Enable RamMoreThan3GB
RUN sed -i 's/gRaspberryPiTokenSpaceGuid.PcdRamMoreThan3GB|L"RamMoreThan3GB"|gConfigDxeFormSetGuid|0x0|0/gRaspberryPiTokenSpaceGuid.PcdRamMoreThan3GB|L"RamMoreThan3GB"|gConfigDxeFormSetGuid|0x0|1/' edk2-platforms/Platform/RaspberryPi/RPi4/RPi4.dsc
# Disable RamLimitTo3GB
RUN sed -i 's/gRaspberryPiTokenSpaceGuid.PcdRamLimitTo3GB|L"RamLimitTo3GB"|gConfigDxeFormSetGuid|0x0|1/gRaspberryPiTokenSpaceGuid.PcdRamLimitTo3GB|L"RamLimitTo3GB"|gConfigDxeFormSetGuid|0x0|0/' edk2-platforms/Platform/RaspberryPi/RPi4/RPi4.dsc
# set gBootDiscoveryPolicyMgrFormsetGuid to Connect Network Devices
RUN sed -i 's/gEfiMdeModulePkgTokenSpaceGuid.PcdBootDiscoveryPolicy|L"BootDiscoveryPolicy"|gBootDiscoveryPolicyMgrFormsetGuid|0/gEfiMdeModulePkgTokenSpaceGuid.PcdBootDiscoveryPolicy|L"BootDiscoveryPolicy"|gBootDiscoveryPolicyMgrFormsetGuid|0|1/' edk2-platforms/Platform/RaspberryPi/RPi4/RPi4.dsc


# Build UEFI firmware
COPY build.sh ./
RUN ./build.sh

# Copy final firmware file
RUN cp Build/RPi4/RELEASE_${COMPILER}/FV/RPI_EFI.fd .

# Download Raspberry Pi support files
RUN curl -O -L $RPI_FIRMWARE_URL/raw/$START_ELF_VERSION/boot/fixup4.dat && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$START_ELF_VERSION/boot/start4.elf && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTB_VERSION/boot/bcm2711-rpi-4-b.dtb && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTB_VERSION/boot/bcm2711-rpi-cm4.dtb && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTB_VERSION/boot/bcm2711-rpi-400.dtb && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTBO_VERSION/boot/overlays/miniuart-bt.dtbo && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTBO_VERSION/boot/overlays/upstream-pi4.dtbo && \
    mkdir overlays && mv *.dtbo overlays

# Create final archive
RUN zip -r RPi4_UEFI_Firmware_${RPi4_VERSION}.zip RPI_EFI.fd *.dtb config.txt fixup4.dat start4.elf overlays Readme.md firmware

RUN sha256sum Build/RPi4/*/FV/RPI_EFI.fd RPi4_UEFI_Firmware_${RPi4_VERSION}.zip

# Final output
CMD ["bash", "-c", "ls -lah /workspace/RPi4_UEFI_Firmware_*.zip"]
