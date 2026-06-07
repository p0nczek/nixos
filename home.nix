{ pkgs, inputs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

home.stateVersion = "25.11"; 

home.file.".zshrc".source = ./zshrc;
home.file.".p10k.zsh".source = ./zsh/.p10k.zsh;
home.file.".local/share/zinit" = {
  source = ./zsh-plugins/zinit;
  recursive = true;
  force = true;
};

# home.nix
home.file.".vst/yabridge".source = "${pkgs.yabridge}/lib/yabridge";

home.file.".config/zsh" = {
  source = ./zsh-config;
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


# w home.nix lub configuration.nix
home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
};


 systemd.user.targets.niri-session = {
    Unit = {
      Description = "niri compositor session";
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
    };
  }; 

  # Niri
  xdg.configFile."niri".source = ./niri;
  xdg.configFile."noctalia".source = ./noctalia;
  xdg.configFile."kitty".source = ./kitty-config;

  home.packages = with pkgs; [
    mpv
    obsidian
    renoise
    telegram-desktop
    vesktop
    discord
    reaper
    pavucontrol
    qpwgraph
    lsp-plugins
    llama-cpp
    lmstudio
    obs-studio
    obs-studio-plugins.wlrobs
    losslesscut-bin
    p7zip
    unrar
    pamixer
    playerctl
    python3
    slurp
    gpu-screen-recorder-gtk
  ];

  programs.zsh = {
    enable = true;
    history.size = 100000;
    history.path = "$HOME/.zsh_history";
  };

}