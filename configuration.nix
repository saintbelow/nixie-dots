
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # LUKS
  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/nvme0n1p2";
      preLVM = false;
    };
  };

  # Filesystems
  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
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

  # Rest of your config (users, networking, etc.)
  users.users.brownjeesus = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme";
  };

  system.stateVersion = "24.11";
}