{ config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # LUKS2
  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/nvme0n1p2";
      allowDiscards = true;
      preLVM = true;
    };
  };

  # Filesystems
  fileSystems."/" = {
    device = lib.mkForce "/dev/mapper/nixos-vg-nixos-lv";  # Fix conflict
    fsType = "btrfs";
    options = [ "subvol=@" "rw" "noatime" "discard=async" "compress-force=zstd" "space_cache=v2" "commit=120" ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/nixos-vg-nixos-lv";
    fsType = "btrfs";
    options = [ "subvol=@home" "rw" "noatime" "discard=async" "compress-force=zstd" "space_cache=v2" "commit=120" ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/nixos-vg-nixos-lv";
    fsType = "btrfs";
    options = [ "subvol=@nix" "rw" "noatime" "discard=async" "compress-force=zstd" "space_cache=v2" "commit=120" ];
  };

  fileSystems."/etc/nixos" = {
    device = "/dev/mapper/nixos-vg-nixos-lv";
    fsType = "btrfs";
    options = [ "subvol=@nixos-config" "rw" "noatime" "discard=async" "compress-force=zstd" "space_cache=v2" "commit=120" ];
  };

  fileSystems."/var/log" = {
    device = "/dev/mapper/nixos-vg-nixos-lv";
    fsType = "btrfs";
    options = [ "subvol=@log" "rw" "noatime" "discard=async" "compress-force=zstd" "space_cache=v2" "commit=120" ];
  };

  fileSystems."/snapshots" = {
    device = "/dev/mapper/nixos-vg-nixos-lv";
    fsType = "btrfs";
    options = [ "subvol=@snapshots" "rw" "noatime" "discard=async" "compress-force=zstd" "space_cache=v2" "commit=120" ];
  };

  fileSystems."/boot" = {
    device = "/dev/nvme0n1p1";
    fsType = "vfat";
    options = [ "rw" "noatime" ];
  };

  # Swap
  swapDevices = [ { device = "/swapfile"; } ];

  # Networking
  networking.hostName = "nixos-beast";
  networking.networkmanager.enable = true;

  # Users
  users.users.brownjeesus = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme";
  };

  # Basic CLI Packages
  environment.systemPackages = with pkgs; [
    vim git htop btop tmux cmatrix mpv wget curl neofetch
  ];

  # Services
  services.openssh.enable = true;
  services.xserver.enable = false;  # No GUI

  # System Version
  system.stateVersion = "24.11";
}