{ pkgs, inputs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  home.stateVersion = "25.11"; 

  # ZSH + OhMyZsh + p10k + zinit
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "zsh-autosuggestions" "zsh-syntax-highlighting" ];
    };
  };

  home.file.".zshrc".source = ./zshrc;
  home.file.".p10k.zsh".source = ./zsh/p10k.zsh;
  home.file.".local/share/zinit" = {
    source = ./zsh-plugins/zinit;
    recursive = true;
    force = true;
  };

  # Noctalia
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

  # Niri
  xdg.configFile."niri".source = ./niri;
  xdg.configFile."noctalia".source = ./noctalia;
}
