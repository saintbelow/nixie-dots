{
  imports = [ ./hardware-configuration.nix ];

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/nvme0n1p2";
    allowDiscards = true; # Improves SSD performance
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

  # Networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Desktop Environment: Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true; # For compatibility with X11 apps
  };

  # Display Manager
  services.displayManager = {
    defaultSession = "hyprland";
    gdm = {
      enable = true;
      wayland = true;
    };
  };

  # System Packages
  environment.systemPackages = with pkgs; [
    kitty # Terminal emulator
    eww # Wayland widgets
    google-chrome # Web browser
    thunar # File manager
    vscode # Code editor
  ];

  # Enable XDG portal for Wayland
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Btrfs and system settings
  boot.kernelPackages = pkgs.linuxPackages_latest;
  system.stateVersion = "24.11"; # Adjust based on your NixOS version
}