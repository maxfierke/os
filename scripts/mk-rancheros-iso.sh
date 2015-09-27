#!/bin/bash
set -ex

cd $(dirname $0)/..
. scripts/build-common

CD=${BUILD}/cd

mkdir -p ${CD}/boot/isolinux

# Build out UEFI boot image
mkfs.vfat -C ${BUILD}/efiboot.img 36000
mmd -i ${BUILD}/efiboot.img EFI
mmd -i ${BUILD}/efiboot.img EFI/boot
mmd -i ${BUILD}/efiboot.img boot
mcopy -i ${BUILD}/efiboot.img \
    /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi \
    ::/EFI/boot/bootx64.efi
mcopy -i ${BUILD}/efiboot.img \
    /usr/lib/syslinux/modules/efi64/ldlinux.e64 \
    ::/EFI/boot/ldlinux.e64
mcopy -i ${BUILD}/efiboot.img \
    /usr/lib/syslinux/modules/efi64/menu.c32 \
    ::/EFI/boot/menu.c32
mcopy -i ${BUILD}/efiboot.img \
    /usr/lib/syslinux/modules/efi64/libcom32.c32 \
    ::/EFI/boot/libcom32.c32
mcopy -i ${BUILD}/efiboot.img \
    /usr/lib/syslinux/modules/efi64/libutil.c32 \
    ::/EFI/boot/libutil.c32
mcopy -i ${BUILD}/efiboot.img \
    scripts/isolinux.cfg \
    ::/EFI/boot/syslinux.cfg
mcopy -i ${BUILD}/efiboot.img \
    ${DIST}/artifacts/vmlinuz \
    ::/boot/vmlinuz
mcopy -i ${BUILD}/efiboot.img \
    ${DIST}/artifacts/initrd \
    ::/boot/initrd

cp ${DIST}/artifacts/initrd                   ${CD}/boot
cp ${DIST}/artifacts/vmlinuz                  ${CD}/boot
cp scripts/isolinux.cfg                       ${CD}/boot/isolinux
cp /usr/lib/ISOLINUX/isolinux.bin             ${CD}/boot/isolinux
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 ${CD}/boot/isolinux
cp ${BUILD}/efiboot.img                       ${CD}/boot/isolinux

cd ${CD} && xorriso \
    -publisher "Rancher Labs, Inc." \
    -as mkisofs \
    -l -J -R -V "RancherOS" \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -eltorito-alt-boot \
    -e boot/isolinux/efiboot.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -o ${DIST}/artifacts/rancheros.iso \
    ${CD}
