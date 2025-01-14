# Raspberry Pi 4 UEFI docker builder

## Build

```sh
docker build -t rpi4-uefi-builder .
docker create --name rpi4-uefi-builder -it rpi4-uefi-builder
docker cp rpi4-uefi-builder:/workspace/RPi4_UEFI_Firmware_v1.38.zip .
docker rm rpi4-uefi-builder
```
