{ config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # LUKS Encryption
  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/nvme0n1p2";
      preLVM = false;
    };
  };

  # Filesystems
  fileSystems."/" = {
    device = lib.mkForce "/dev/mapper/cryptroot";  # Override UUID conflict
    fsType = "btrfs";
    options = [ "subvol=root" "compress=zstd" ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=home" "compress=zstd" ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=nix" "compress=zstd" ];
  };

  fileSystems."/snapshots" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=snapshots" "compress=zstd" ];
  };

  fileSystems."/boot" = {
    device = "/dev/nvme0n1p1";
    fsType = "vfat";
  };

  # Swap
  swapDevices = [ { device = "/swapfile"; } ];

  # Networking
  networking.hostName = "nixos-beast";
  networking.networkmanager.enable = true;

  # Users
  users.users.brownjeesus = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];  # sudo and Wi-Fi access
    initialPassword = "changeme";  # Change after boot
  };

  # Basic CLI Packages
  environment.systemPackages = with pkgs; [
    vim  # Editor
    git  # Version control
    htop btop  # System monitoring
    tmux  # Terminal multiplexer
    cmatrix  # Hacker vibe
    mpv  # Music/video player
    wget curl  # Networking tools
    neofetch  # System info flex
  ];

  # Services
  services.openssh.enable = true;  # SSH access
  services.xserver.enable = false;  # No GUI

  # System Version
  system.stateVersion = "24.11";  # Adjust if needed
}