#!/bin/bash

set -e

# Step 1: Partitioning /dev/nvme0n1
echo "Partitioning /dev/nvme0n1..."
parted /dev/nvme0n1 --script -- mklabel gpt
parted /dev/nvme0n1 --script -- mkpart ESP fat32 1MiB 513MiB
parted /dev/nvme0n1 --script -- mkpart primary 513MiB 100%

# Step 2: Formatting EFI partition
echo "Formatting EFI partition..."
mkfs.vfat -F 32 /dev/nvme0n1p1

# Step 3: Encrypting root partition with LUKS2
echo "Encrypting root partition with LUKS2..."
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
cryptsetup luksOpen /dev/nvme0n1p2 cryptroot

# Step 4: Setting up LVM
echo "Setting up LVM..."
vgcreate vg_nixos /dev/mapper/cryptroot
lvcreate -l +100%FREE -n lv_root vg_nixos

# Step 5: Formatting with BTRFS
echo "Formatting with BTRFS..."
mkfs.btrfs /dev/mapper/vg_nixos-lv_root

# Step 6: Mounting BTRFS and creating subvolumes
echo "Mounting BTRFS and creating subvolumes..."
mount /dev/mapper/vg_nixos-lv_root /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@nixos-config
btrfs subvolume create /mnt/@log
umount /mnt

# Step 7: Mounting subvolumes with compression and noatime
echo "Mounting subvolumes..."
mount -o subvol=@,compress=zstd,noatime /dev/mapper/vg_nixos-lv_root /mnt
mount -o subvol=@home,compress=zstd,noatime /dev/mapper/vg_nixos-lv_root /mnt/home
mount -o subvol=@snapshots,compress=zstd,noatime /dev/mapper/vg_nixos-lv_root /mnt/nix/var/nix/gcroots/impermanence/snapshots
mount -o subvol=@nix,compress=zstd,noatime /dev/mapper/vg_nixos-lv_root /mnt/nix
mount -o subvol=@nixos-config,compress=zstd,noatime /dev/mapper/vg_nixos-lv_root /mnt/etc/nixos
mount -o subvol=@log,compress=zstd,noatime /dev/mapper/vg_nixos-lv_root /mnt/var/log

# Step 8: Creating swap file
echo "Creating swap file..."
fallocate -l 8G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile

# Step 9: Mounting EFI partition
echo "Mounting EFI partition..."
mount /dev/nvme0n1p1 /mnt/boot

echo "Setup complete, bhai. Ab Donovan Glover ka nix-config use kar ke nixos-install kar de, cuh."