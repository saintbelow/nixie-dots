{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader for EFI with encrypted root
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."enc".device = "/dev/disk/by-uuid/<luks_uuid>";

  # Filesystems (BTRFS subvolumes)
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/<btrfs_uuid>";
    fsType = "btrfs";
    options = [ "subvol=root" "compress=zstd" "noatime" ];
  };
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/<btrfs_uuid>";
    fsType = "btrfs";
    options = [ "subvol=home" "compress=zstd" "noatime" ];
  };
  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/<btrfs_uuid>";
    fsType = "btrfs";
    options = [ "subvol=nix" "compress=zstd" "noatime" ];
  };
  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/<btrfs_uuid>";
    fsType = "btrfs";
    options = [ "subvol=persist" "compress=zstd" "noatime" ];
  };
  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/<btrfs_uuid>";
    fsType = "btrfs";
    options = [ "subvol=log" "compress=zstd" "noatime" ];
  };
  fileSystems."/boot" = {
    device = "/dev/nvme0n1p1";
    fsType = "vfat";
  };

  # Networking (WiFi)
  networking.hostName = "nixos";  # Change this if you want
  networking.wireless.enable = true;
  networking.wireless.networks."<your_SSID>".psk = "<your_password>";

  # Time zone
  time.timeZone = "America/New_York";  # Replace with your time zone

  # User setup
  users.users.yourusername = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "yourpassword";
  };

  # Hyprland
  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;
  services.displayManager.defaultSession = "none+hyprland";
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "yourusername";
  
  # Allow unfree packages (for Google Chrome)
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [ google-chrome ];

  # System version
  system.stateVersion = "23.11";  # Match your NixOS version
}