{
  imports = [ ./hardware-configuration.nix ];

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/nvme0n1p2";
    allowDiscards = true; # Optional: Improves SSD performance
  };

  # Filesystems
  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=root" "compress=zstd" "noatime" ];
  };
  fileSystems."/home" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=home" "compress=zstd" "noatime" ];
  };
  fileSystems."/var/log" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=log" "compress=zstd" "noatime" ];
  };
  fileSystems."/persist" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=persist" "compress=zstd" "noatime" ];
  };
  fileSystems."/etc/nixos" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=nixos" "compress=zstd" "noatime" ];
  };
  fileSystems."/nix" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=nix" "compress=zstd" "noatime" ];
  };
  fileSystems."/boot" = {
    device = "/dev/nvme0n1p1";
    fsType = "vfat";
  };

  # Swap
  swapDevices = [
    { device = "/swap/swapfile"; }
  ];

  # Enable networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Btrfs and system settings
  boot.kernelPackages = pkgs.linuxPackages_latest;
  system.stateVersion = "24.11"; # Adjust based on your NixOS version
}