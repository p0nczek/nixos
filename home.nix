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
  xdg.configFile."niri".source = ./niri;
  xdg.configFile."noctalia".source = ./noctalia;
  home.file.".zshrc".source = ./zshrc;
  home.file.".config/zsh".source = ./zsh-config;
}
