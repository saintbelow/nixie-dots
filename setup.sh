#!/bin/bash

# Exit on any error to avoid screwing up your drive, bhai
set -e

# Variables for easier tweaking
DRIVE="/dev/nvme0n1"
EFI_PART="${DRIVE}p1"
LINUX_PART="${DRIVE}p2"
CRYPT_NAME="cryptroot"
MOUNT_OPTS="space_cache=v2,ssd,compress=zstd,noatime"

echo "Starting setup for ${DRIVE}, bhai. Let’s make this SSD fly! 🔥"

# Step 1: Clean the drive (delete partitions and encryption)
echo "Wiping ${DRIVE} clean..."
# Unmount anything on the drive if mounted
umount ${DRIVE}* 2>/dev/null || true
# Close any open LUKS containers
cryptsetup luksClose ${CRYPT_NAME} 2>/dev/null || true
# Wipe partition table
parted ${DRIVE} --script -- mklabel gpt
echo "Drive cleaned, bhai. All partitions and encryption gone!"

# Step 2: Create partitions
echo "Partitioning ${DRIVE}..."
parted ${DRIVE} --script -- mkpart ESP fat32 1MiB 513MiB
parted ${DRIVE} --script -- set 1 esp on
parted ${DRIVE} --script -- mkpart primary 513MiB 100%
echo "Partitions created: EFI (512MB) and Linux (rest of the space)."

# Step 3: Format EFI partition
echo "Formatting EFI partition (${EFI_PART})..."
mkfs.vfat -F 32 ${EFI_PART}
echo "EFI partition formatted with FAT32."

# Step 4: Set up LUKS2 encryption on Linux partition
echo "Encrypting ${LINUX_PART} with LUKS2..."
cryptsetup luksFormat --type luks2 ${LINUX_PART}
echo "Opening encrypted partition..."
cryptsetup luksOpen ${LINUX_PART} ${CRYPT_NAME}
echo "LUKS2 encryption set up, bhai. Passphrase locked in!"

# Step 5: Format with BTRFS (no LVM, direct on encrypted partition)
echo "Formatting /dev/mapper/${CRYPT_NAME} with BTRFS..."
mkfs.btrfs /dev/mapper/${CRYPT_NAME}
echo "BTRFS formatted, ready for subvolumes."

# Step 6: Create BTRFS subvolumes
echo "Mounting BTRFS temporarily to create subvolumes..."
mount /dev/mapper/${CRYPT_NAME} /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@nixos-config
btrfs subvolume create /mnt/@log
umount /mnt
echo "Subvolumes created: @, @home, @snapshots, @nix, @nixos-config, @log."

# Step 7: Mount subvolumes with SSD optimizations
echo "Mounting subvolumes with ${MOUNT_OPTS}..."
mount -o subvol=@,${MOUNT_OPTS} /dev/mapper/${CRYPT_NAME} /mnt
mkdir -p /mnt/{home,nix/var/nix/gcroots/impermanence/snapshots,etc/nixos,var/log,boot}
mount -o subvol=@home,${MOUNT_OPTS} /dev/mapper/${CRYPT_NAME} /mnt/home
mount -o subvol=@snapshots,${MOUNT_OPTS} /dev/mapper/${CRYPT_NAME} /mnt/nix/var/nix/gcroots/impermanence/snapshots
mount -o subvol=@nix,${MOUNT_OPTS} /dev/mapper/${CRYPT_NAME} /mnt/nix
mount -o subvol=@nixos-config,${MOUNT_OPTS} /dev/mapper/${CRYPT_NAME} /mnt/etc/nixos
mount -o subvol=@log,${MOUNT_OPTS} /dev/mapper/${CRYPT_NAME} /mnt/var/log
echo "Subvolumes mounted with SSD speed boosts, bhai!"

# Step 8: Create and configure 8GB swap file
echo "Creating 8GB swap file in root subvolume..."
fallocate -l 8G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
echo "Swap file created and ready."

# Step 9: Mount EFI partition
echo "Mounting EFI partition (${EFI_PART})..."
mount ${EFI_PART} /mnt/boot
echo "EFI partition mounted at /mnt/boot."

echo "Setup complete, bhai! Drive is clean, encrypted, and optimized. 🚀"

# Final instructions
echo "Next steps:"
echo "1. Clone Donovan Glover’s nix-config: git clone https://github.com/donovanglover/nix-config /mnt/etc/nixos/nix-config"
echo "2. Cd into it: cd /mnt/etc/nixos/nix-config"
echo "3. Install NixOS: nixos-install --flake .#nixos"
echo "4. Reboot and vibe with Hyprland, cuh! 😎"