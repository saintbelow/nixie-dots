#!/usr/bin/env bash
# reset-lvm-nixos.sh

set -euo pipefail

DEVICE="/dev/nvme0n1"
CRYPT_PART="${DEVICE}p2"
CRYPT_NAME="cryptroot"
VG_NAME="nixos-ug"
LV_NAME="nixos-lu"

echo "[+] Switching to root if not already (sudo required for some commands)"
[ "$EUID" -ne 0 ] && { echo "Run as root!"; exit 1; }

echo "[+] Opening LUKS encrypted partition: $CRYPT_PART"
cryptsetup open "$CRYPT_PART" "$CRYPT_NAME"

echo "[+] Showing current Logical Volumes:"
lvs || true

echo "[+] Deactivating logical volume $VG_NAME/$LV_NAME"
lvchange -an "${VG_NAME}/${LV_NAME}" || true

echo "[+] Deactivating volume group $VG_NAME"
vgchange -an || true

echo "[+] Removing logical volume $VG_NAME/$LV_NAME"
lvremove -y "${VG_NAME}/${LV_NAME}" || true

echo "[+] Removing volume group $VG_NAME"
vgremove -y "$VG_NAME" || true

echo "[+] Removing physical volume labels from /dev/mapper/$CRYPT_NAME"
pvremove "/dev/mapper/${CRYPT_NAME}" || true

echo "[+] Closing LUKS device $CRYPT_NAME"
cryptsetup close "$CRYPT_NAME" || true

echo "[+] Wiping partition table signatures from $DEVICE"
wipefs -a "$DEVICE"

echo "[+] Re-reading partition table"
partprobe "$DEVICE"

echo "[+] Done. Disk is wiped and clean."