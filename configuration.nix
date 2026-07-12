{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/system/xkb.nix
    ./modules/system/boot.nix
    ./modules/system/networking.nix
    ./modules/system/locale.nix
    ./modules/system/nix-settings.nix
    ./modules/system/nvidia.nix
    ./modules/system/audio.nix
    ./modules/system/desktop.nix
    ./modules/system/flatpak.nix
    ./modules/system/steam-obs.nix
    ./modules/system/users.nix
    ./modules/system/packages.nix
    #./modules/system/qmk.nix
  ];

  # Managed by the `nn` helper. Do not edit manually.
  system.nixos.label = "stable_";

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";

  system.stateVersion = "25.11";
}
