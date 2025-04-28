#!/bin/bash
set -e  # Exit immediately if any command fails

# Define disk and partition details
DISK="/dev/nvme0n1"
EFI_PARTITION="${DISK}p1"
ROOT_PARTITION="${DISK}p2"
CRYPT_NAME="cryptroot"
VG_NAME="nixos-vg"
LV_NAME="nixos-lv"
BTRFS_OPT="rw,noatime,discard=async,compress-force=zstd,space_cache=v2,commit=120"
SWAP_SIZE="8G"
SWAPFILE="/mnt/swapfile"

# Wipe the disk
echo "Wiping the disk..."
sudo wipefs -a "$DISK"

# Create GPT partition table and partitions
echo "Creating GPT partition table and partitions..."
sudo parted --script "$DISK" mklabel gpt
sudo parted --script "$DISK" mkpart ESP fat32 1MiB 1GiB
sudo parted --script "$DISK" set 1 boot on
sudo parted --script "$DISK" mkpart primary 1GiB 100%

# Format the EFI partition
echo "Formatting EFI partition..."
sudo mkfs.vfat -n EFI "$EFI_PARTITION"

# Encrypt the root partition with LUKS2
echo "Encrypting root partition with LUKS2..."
sudo cryptsetup luksFormat --type=luks2 "$ROOT_PARTITION"
sudo cryptsetup open "$ROOT_PARTITION" "$CRYPT_NAME"

# Set up LVM
echo "Setting up LVM..."
sudo vgcreate "$VG_NAME" "/dev/mapper/$CRYPT_NAME"
sudo lvcreate --name "$LV_NAME" -l +100%FREE "$VG_NAME"

# Format the logical volume with BTRFS
echo "Creating BTRFS filesystem..."
sudo mkfs.btrfs -L NixOS "/dev/mapper/$VG_NAME-$LV_NAME"

# Mount the root partition and create BTRFS subvolumes
echo "Mounting the root partition and creating subvolumes..."
sudo mount -o $BTRFS_OPT "/dev/mapper/$VG_NAME-$LV_NAME" /mnt
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@snapshots
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume create /mnt/@nixos-config
sudo btrfs subvolume create /mnt/@log
sudo umount /mnt

# Mount subvolumes with specific options
echo "Mounting subvolumes..."
sudo mount -o $BTRFS_OPT,subvol=@ "/dev/mapper/$VG_NAME-$LV_NAME" /mnt
sudo mkdir -p /mnt/{home,nix,etc/nixos,var/log,boot,snapshots}
sudo mount -o $BTRFS_OPT,subvol=@home "/dev/mapper/$VG_NAME-$LV_NAME" /mnt/home
sudo mount -o $BTRFS_OPT,subvol=@nix "/dev/mapper/$VG_NAME-$LV_NAME" /mnt/nix
sudo mount -o $BTRFS_OPT,subvol=@nixos-config "/dev/mapper/$VG_NAME-$LV_NAME" /mnt/etc/nixos
sudo mount -o $BTRFS_OPT,subvol=@log "/dev/mapper/$VG_NAME-$LV_NAME" /mnt/var/log
sudo mount -o $BTRFS_OPT,subvol=@snapshots "/dev/mapper/$VG_NAME-$LV_NAME" /mnt/snapshots

# Mount the EFI partition
echo "Mounting EFI partition..."
sudo mount -o rw,noatime "$EFI_PARTITION" /mnt/boot

# Set up swapfile
echo "Setting up swapfile..."
sudo truncate -s 0 "$SWAPFILE"
sudo chattr +C "$SWAPFILE"
sudo fallocate -l "$SWAP_SIZE" "$SWAPFILE"
sudo chmod 0600 "$SWAPFILE"
sudo mkswap "$SWAPFILE"
sudo swapon "$SWAPFILE"

echo "Disk setup complete!"

# You can now run nixos-install
echo "Run nixos-install after this setup to complete installation."