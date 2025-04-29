#!/usr/bin/env bash

set -euo pipefail

DISK="/dev/nvme0n1"
CRYPT_NAME="cryptroot"
EFI_PART="${DISK}p1"
ROOT_PART="${DISK}p2"

log() {
  echo -e "\033[1;32m[SaintBelow Setup]\033[0m $1"
}

error_exit() {
  echo -e "\033[1;31m[ERROR]\033[0m $1"
  exit 1
}

require_root() {
  [[ $EUID -ne 0 ]] && error_exit "This script must be run as root"
}

partition_disk() {
  log "Wiping and partitioning $DISK..."
  wipefs -a "$DISK"
  sgdisk -Zo "$DISK"

  parted "$DISK" -- mklabel gpt
  parted "$DISK" -- mkpart ESP fat32 1MiB 551MiB
  parted "$DISK" -- set 1 esp on
  parted "$DISK" -- mkpart primary 551MiB 100%
}

encrypt_root() {
  log "Encrypting root partition with LUKS2..."
  cryptsetup luksFormat --type luks2 "$ROOT_PART"
  cryptsetup open "$ROOT_PART" "$CRYPT_NAME"
}

format_filesystems() {
  log "Formatting filesystems..."
  mkfs.vfat -n EFI "$EFI_PART"
  mkfs.btrfs -L NIXROOT "/dev/mapper/$CRYPT_NAME"
}

create_subvolumes() {
  log "Creating Btrfs subvolumes..."
  mount "/dev/mapper/$CRYPT_NAME" /mnt
  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@home
  btrfs subvolume create /mnt/@nix
  btrfs subvolume create /mnt/@persist
  umount /mnt
}

mount_layout() {
  log "Mounting layout with subvolumes..."
  mount -o compress=zstd,subvol=@ "/dev/mapper/$CRYPT_NAME" /mnt

  mkdir -p /mnt/{boot,home,nix,persist}
  mount -o compress=zstd,subvol=@home "/dev/mapper/$CRYPT_NAME" /mnt/home
  mount -o compress=zstd,subvol=@nix "/dev/mapper/$CRYPT_NAME" /mnt/nix
  mount -o compress=zstd,subvol=@persist "/dev/mapper/$CRYPT_NAME" /mnt/persist
  mount "$EFI_PART" /mnt/boot
}

enable_flakes() {
  log "Enabling Flakes..."
  mkdir -p /mnt/etc/nix
  echo "experimental-features = nix-command flakes" > /mnt/etc/nix/nix.conf
}

generate_hw_config() {
  log "Generating hardware configuration..."
  nixos-generate-config --root /mnt
}

finalize() {
  log "Done! Disk is ready. Now clone your flake config into /mnt/etc/nixos and run:"
  echo
  echo "    nixos-install --flake /mnt/etc/nixos#your-hostname"
  echo
}

main() {
  require_root
  partition_disk
  encrypt_root
  format_filesystems
  create_subvolumes
  mount_layout
  enable_flakes
  generate_hw_config
  finalize
}

main "$@"