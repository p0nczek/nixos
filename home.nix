{ pkgs, inputs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  # ============================================================================
  #  HOME STATE VERSION
  # ============================================================================
  # Keep this equal to the NixOS stateVersion from configuration.nix.
  home.stateVersion = "25.11";

  # ============================================================================
  #  DOTFILES (managed by Home Manager)
  # ============================================================================
  home.file.".zshrc".source = ./zshrc;
  home.file.".p10k.zsh".source = ./zsh/.p10k.zsh;

  home.file.".local/share/zinit" = {
    source = ./zsh-plugins/zinit;
    recursive = true;
    force = true;
  };

  home.file.".config/zsh" = {
    source = ./zsh-config;
    recursive = true;
    force = true;
  };

  # Btop
  home.file.".config/btop/themes/noctalia.theme".source = ./btop-noctalia.theme;
  # VST bridge for Windows plugins (Yabridge)
  home.file.".vst/yabridge".source = "${pkgs.yabridge}/lib/yabridge";

  # ============================================================================
  #  XDG CONFIG (symlinked into ~/.config)
  # ============================================================================
  xdg.configFile."niri".source = ./niri;
  xdg.configFile."noctalia".source = ./noctalia;
  xdg.configFile."kitty".source = ./kitty-config;

  # ============================================================================
  #  ENVIRONMENT
  # ============================================================================
  # Make flake path available to nh / nix commands without typing it every time.
  home.sessionVariables = {
    NH_FLAKE = "/etc/nixos";
  };

  # Ensure ~/.local/bin is on PATH (for uv/pip --user installs, etc.)
  home.sessionPath = [ "$HOME/.local/bin" ];

  # ============================================================================
  #  CURSOR THEME
  # ============================================================================
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
  };

  # ============================================================================
  #  NOCTALIA SHELL
  # ============================================================================
  programs.noctalia-shell = {
    enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
      calendarSupport = true;
    };
    settings = {
      bar = {
        position = "top";
        density = "default";
      };
    };
  };

  # ============================================================================
  #  SYSTEMD USER TARGET (Niri session)
  # ============================================================================
  systemd.user.targets.niri-session = {
    Unit = {
      Description = "niri compositor session";
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
    };
  };



  # ============================================================================
  #  USER PACKAGES
  # ============================================================================
  home.packages = with pkgs; [

    # --- Audio / Music Production ---
    reaper
    renoise
    pavucontrol
    qpwgraph
    lsp-plugins
    pamixer
    playerctl

    
    wineWow64Packages.stable
    yabridge
    yabridgectl
    winetricks
    qjackctl

    # --- Video / Streaming ---
    mpv
    obs-studio
    obs-studio-plugins.wlrobs
    gpu-screen-recorder-gtk
    losslesscut-bin
    slurp

    # --- Communication ---
    telegram-desktop
    vesktop
    discord

    # --- AI / ML ---
    llama-cpp
    lmstudio

    # --- Productivity ---
    obsidian


    # --- System / Utilities ---
    nautilus
    p7zip
    unrar
    python3
    eza
    bat
    fd
    ripgrep
    fzf
    zoxide
    btop
    fastfetch
    ffmpeg
    atuin
    libnotify




    qmk
    dfu-programmer 
    avrdude
  ] ++ [
    # --- External flakes (not in nixpkgs) ---
    inputs.zen-browser.packages.${pkgs.system}.default
    inputs.kimi-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

}
