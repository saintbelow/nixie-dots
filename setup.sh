#!/usr/bin/env bash
# setup.sh -- automated NixOS disk layout & encryption
# by Jane the chill goth hacker 👩‍💻🦇

set -euo pipefail

### Configuration
DRIVE="/dev/nvme0n1"
EFI_PART="${DRIVE}p1"
ROOT_PART="${DRIVE}p2"
CRYPT_NAME="cryptroot"
MOUNT_OPTS="ssd,compress=zstd,noatime"

echo "🚀 Starting NixOS disk setup on ${DRIVE}..."

### 1. Clean Slate
echo "🗑️  Wiping existing partitions & LUKS..."
umount "${DRIVE}"*   2>/dev/null || true
cryptsetup luksClose "${CRYPT_NAME}" 2>/dev/null || true
parted "${DRIVE}" --script mklabel gpt

### 2. Partitioning
echo "📐 Creating GPT partitions..."
parted "${DRIVE}" --script mkpart ESP fat32 1MiB 513MiB
parted "${DRIVE}" --script set 1 esp on
parted "${DRIVE}" --script mkpart primary 513MiB 100%

### 3. Format EFI
echo "🎨 Formatting EFI ($(basename "${EFI_PART}")) as FAT32..."
mkfs.vfat -F32 "${EFI_PART}"

### 4. LUKS Encryption
echo "🔐 Setting up LUKS2 on $(basename "${ROOT_PART}")..."
cryptsetup luksFormat --type luks2 "${ROOT_PART}"
cryptsetup luksOpen "${ROOT_PART}" "${CRYPT_NAME}"

### 5. BTRFS & Subvolumes
echo "🌲 Formatting encrypted root as BTRFS..."
mkfs.btrfs /dev/mapper/"${CRYPT_NAME}"

echo "🛠️  Creating subvolumes..."
mount /dev/mapper/"${CRYPT_NAME}" /mnt
for SV in @ @home @snapshots @nix @log @nixos-config; do
    btrfs subvolume create /mnt/"${SV}"
done
umount /mnt

### 6. Mounting
echo "🔧 Mounting subvolumes with options: ${MOUNT_OPTS}"
mount -o subvol=@,${MOUNT_OPTS} /dev/mapper/"${CRYPT_NAME}" /mnt

# Ensure all mount points exist
mkdir -p /mnt/{boot,home,snapshots,nix,var/log,etc/nixos}

mount -o subvol=@home,${MOUNT_OPTS}        /dev/mapper/"${CRYPT_NAME}" /mnt/home
mount -o subvol=@snapshots,${MOUNT_OPTS} /dev/mapper/"${CRYPT_NAME}" /mnt/snapshots
mount -o subvol=@nix,${MOUNT_OPTS}       /dev/mapper/"${CRYPT_NAME}" /mnt/nix
mount -o subvol=@log,${MOUNT_OPTS}       /dev/mapper/"${CRYPT_NAME}" /mnt/var/log
# We’re using a dedicated subvolume for /etc/nixos if you want it; otherwise, configs go in /mnt/etc/nixos
mount -o subvol=@nixos-config,${MOUNT_OPTS} /dev/mapper/"${CRYPT_NAME}" /mnt/etc/nixos

### 7. Swapfile
echo "💤 Creating 8 GB swapfile..."
fallocate -l 8G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile

### 8. Mount EFI
echo "✈️  Mounting EFI at /mnt/boot..."
mount "${EFI_PART}" /mnt/boot

### 9. Final Touches
echo "✅ Disk layout done. Next up:"

cat <<EOF

  1. Generate NixOS configs:
     nixos-generate-config --root /mnt

  2. Edit /mnt/etc/nixos/configuration.nix to your taste.

  3. Install NixOS:
     nixos-install

  4. Set root password when prompted, then reboot.

Enjoy your fresh, encrypted NixOS! 🦇✨
EOF