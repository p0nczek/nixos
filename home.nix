{ pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
    inputs.vicinae.homeManagerModules.default
    ./modules/home/sync-configs.nix
    ./modules/home/noctalia.nix
    ./modules/home/vicinae.nix
    ./modules/home/desktop-extras.nix
    ./modules/home/packages.nix
    #./modules/home/ai-stack.nix
  ];

  home.stateVersion = "25.11";
}
