{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Boot Configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd.luks.devices."cryptroot" = {
      device = "/dev/nvme0n1p2";
      allowDiscards = true; # Improves SSD performance on NVMe
    };

    kernelPackages = pkgs.linuxPackages_latest; # Always latest stable kernel
  };

  # Filesystems
  fileSystems = {
    "/" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=root" "compress=zstd" "noatime" ];
    };
    "/home" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=home" "compress=zstd" "noatime" ];
    };
    "/var/log" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=log" "compress=zstd" "noatime" ];
    };
    "/persist" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=persist" "compress=zstd" "noatime" ];
    };
    "/etc/nixos" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=nixos" "compress=zstd" "noatime" ];
    };
    "/nix" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=nix" "compress=zstd" "noatime" ];
    };
    "/boot" = {
      device = "/dev/nvme0n1p1";
      fsType = "vfat";
    };
  };

  # Swap File
  swapDevices = [
    { device = "/swap/swapfile"; }
  ];

  # Networking
  networking = {
    hostName = "nixos"; # Set your hostname
    networkmanager.enable = true; # Easy WiFi/Ethernet handling
  };

  # Hyprland (Wayland compositor)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true; # X11 app support
  };

  # Display Manager
  services.displayManager = {
    defaultSession = "hyprland";
    gdm = {
      enable = true;
      wayland = true;
    };
  };

  # Packages to Install
  environment.systemPackages = with pkgs; [
    kitty            # Terminal emulator
    eww              # Wayland widgets
    google-chrome    # Web browser
    thunar           # File manager
    vscode           # Code editor
  ];

  # XDG Portal (For native Wayland app support)
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Locale (Highly recommended defaults)
  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Asia/Kolkata"; # Change to your timezone

  # Sound (Pulseaudio / Pipewire)
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Users (optional, but pro move for better control)
  users.users.yourusername = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ]; # Sudo and important groups
    shell = pkgs.zsh; # Or bash, fish, whatever you love
  };

  # Allow unfree packages (important for Chrome and stuff)
  nixpkgs.config.allowUnfree = true;

  # State Version
  system.stateVersion = "24.05"; # Adjust based on your NixOS version
}