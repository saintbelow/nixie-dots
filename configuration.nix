{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # LUKS encryption with UUID from /dev/nvme0n1p2
  boot.initrd.luks.devices."enc".device = "/dev/disk/by-uuid/0ea6229d-a3c2-47b6-893d-6742778c7e2c";

  # Filesystem configuration with BTRFS subvolumes
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/a1e79691-c57b-4509-ae9a-71149e1dd9ff";
    fsType = "btrfs";
    options = [ "subvol=root" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/a1e79691-c57b-4509-ae9a-71149e1dd9ff";
    fsType = "btrfs";
    options = [ "subvol=home" "compress=zstd" "noatime" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/a1e79691-c57b-4509-ae9a-71149e1dd9ff";
    fsType = "btrfs";
    options = [ "subvol=nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/a1e79691-c57b-4509-ae9a-71149e1dd9ff";
    fsType = "btrfs";
    options = [ "subvol=persist" "compress=zstd" "noatime" ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/a1e79691-c57b-4509-ae9a-71149e1dd9ff";
    fsType = "btrfs";
    options = [ "subvol=log" "compress=zstd" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/nvme0n1p1";
    fsType = "vfat";
  };

  # Networking configuration
  networking.hostName = "nixos";
  networking.wireless.enable = true;
  # networking.wireless.networks."your_SSID".psk = "your_password";  # Uncomment and set your WiFi details

  # Timezone
  time.timeZone = "Asia/Kolkata";

  # User configuration
  users.users.brownjeesus = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "Bubu9433@#!!";  # Change this after installation for security
  };

  # XServer and Display Manager
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.defaultSession = "hyprland";
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "brownjeesus";

  # Hyprland configuration
  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  # Packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    google-chrome
    kitty
  ];

  # System version
  system.stateVersion = "24.11";
}