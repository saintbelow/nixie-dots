
{ config, pkgs, ... }:

let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz";
in {
  imports = [
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];

  networking.hostName = "saintbelow";
  networking.networkmanager.enable = true;

  users.users.saintbelow = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  programs.hyprland.enable = true;

  services.displayManager.ly.enable = true;

  hardware.opengl = {
    enable = true;
    extraPackages = [ pkgs.intel-media-driver ];
  };

  services.tlp.enable = true;

  boot.initrd.kernelModules = [ "i915" ];

  swapDevices = [ { device = "/swapfile"; } ];

  home-manager.users.saintbelow = { pkgs, ... }: {
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        "$mod" = "SUPER";
        "$terminal" = "kitty";
        "$menu" = "rofi -show drun";

        bind = [
          "$mod, Return, exec, $terminal"
          "$mod, D, exec, $menu"
          "$mod, Q, killactive"
        ] ++ (
          builtins.concatLists (builtins.genList (i:
            let ws = toString (i + 1);
            in [
              "$mod, ${ws}, workspace, ${ws}"
              "$mod SHIFT, ${ws}, movetoworkspace, ${ws}"
            ]
          ) 9)
        );
      };
    };

    home.packages = with pkgs; [
      kitty
      rofi
      networkmanagerapplet
    ];
  };
}