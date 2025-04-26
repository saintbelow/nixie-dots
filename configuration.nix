{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # LUKS configuration with UUID from /dev/nvme0n1p2
  boot.initrd.luks.devices."enc".device = "/dev/disk/by-uuid/0ea6229d-a3c2-47b1-893d-6742778c7e2c";

  # Filesystem configuration with BTRFS UUID from /dev/mapper/enc
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
  # Add your WiFi network here by uncommenting and filling in the details
  networking.wireless.networks."BROWNJESUS-AIRFIBER".psk = "Bubu9433";

  # Timezone
  time.timeZone = "Asia/Kolkata";

  # User configuration
  users.users.brownjeesus = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "Bubu9433@#!!"; # Note: Change this password after initial login for security
  };

  # Hyprland desktop environment with SDDM and auto-login
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.defaultSession = "hyprland";
  services.xserver.displayManager.sddm.autoLogin.enable = true;
  services.xserver.displayManager.sddm.autoLogin.user = "brownjeesus";
  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  # Packages and unfree software
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [ google-chrome ];

  # System state version
  system.stateVersion = "23.11"; # Adjust if using a different NixOS version
}