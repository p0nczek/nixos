{ pkgs, inputs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  home.stateVersion = "25.11"; 

  programs.noctalia-shell = {
    enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.override { calendarSupport = true; };
    
    settings = {
      bar = {
        position = "top";
        density = "default";
      };
    };
  };

  # Poprawne ścieżki – wszystko w folderze niri/
  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;
  xdg.configFile."niri/cfg".source = ./niri/cfg;
  xdg.configFile."niri/noctalia.kdl".source = ./niri/noctalia.kdl;
}
