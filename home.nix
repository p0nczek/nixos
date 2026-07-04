{ pkgs, lib, inputs, ... }:

{


  imports = [
    inputs.noctalia.homeModules.default
  ];


 home.activation.syncAllConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # 1. Dereference: zamień symlinki na kopie + daj write
    for dir in "$HOME/.config/noctalia" "$HOME/.config/kitty" "$HOME/.config/btop" "$HOME/.config/niri" "$HOME/.config/zsh" "$HOME/.local/share/zinit" "$HOME/.local/share/navi/cheats/moje"; do
      [ -d "$dir" ] && find "$dir" -type l -exec sh -c 'for f; do t=$(readlink -f "$f"); rm -f "$f"; cp -f "$t" "$f"; chmod +w "$f"; done' _ {} + 2>/dev/null
      [ -d "$dir" ] && find "$dir" -type f ! -perm /u+w -exec chmod u+w {} + 2>/dev/null
    done
    for f in "$HOME/.zshrc" "$HOME/.p10k.zsh"; do
      [ -L "$f" ] && t=$(readlink -f "$f") && rm -f "$f" && cp -f "$t" "$f" && chmod +w "$f"
      [ -f "$f" ] && chmod +w "$f"
    done

    # 2. Sync z /etc/nixos/ (nadpisz jeśli się różni, ZAWSZE writable)
    sync_config() {
      local src="$1"
      local dst="$2"
      if [ -d "$src" ]; then
        mkdir -p "$dst"
        while IFS= read -r -d ''' file; do
          local rel="''${file#$src/}"
          local dstfile="$dst/$rel"
          mkdir -p "$(dirname "$dstfile")"
          if [ ! -e "$dstfile" ] || ! ${pkgs.diffutils}/bin/diff -q "$file" "$dstfile" >/dev/null 2>&1; then
            cp -f "$file" "$dstfile"
            echo "[sync] $rel"
          fi
          chmod +w "$dstfile" 2>/dev/null
        done < <(${pkgs.findutils}/bin/find "$src" -type f -print0)
      else
        mkdir -p "$(dirname "$dst")"
        if [ ! -e "$dst" ] || ! ${pkgs.diffutils}/bin/diff -q "$src" "$dst" >/dev/null 2>&1; then
          cp -f "$src" "$dst"
          echo "[sync] $(basename "$dst")"
        fi
        chmod +w "$dst" 2>/dev/null
      fi
    }

    sync_config "${toString ./zshrc}" "$HOME/.zshrc"
    sync_config "${toString ./zsh/.p10k.zsh}" "$HOME/.p10k.zsh"
    sync_config "${toString ./zsh-plugins/zinit}" "$HOME/.local/share/zinit"
    sync_config "${toString ./zsh-config}" "$HOME/.config/zsh"
    sync_config "${toString ./niri}" "$HOME/.config/niri"
    sync_config "${toString ./kitty-config}" "$HOME/.config/kitty"
    sync_config "${toString ./noctalia}" "$HOME/.config/noctalia"
    sync_config "${toString ./btop-noctalia.theme}" "$HOME/.config/btop/themes/noctalia.theme"
    sync_config "${toString ./cheats}" "$HOME/.local/share/navi/cheats/moje"
  '';


  # ============================================================================
  #  HOME STATE VERSION
  # ============================================================================
  # Keep this equal to the NixOS stateVersion from configuration.nix.
  home.stateVersion = "25.11";

# w home.nix, np. obok programs.noctalia-shell
  programs.navi = {
    enable = true;
    settings = {
      style = {
        tag = { color = "magenta"; };
        comment = { color = "blue"; };
        snippet = { color = "white"; };
      };
    };
  };

  # VST bridge for Windows plugins (Yabridge)
  home.file.".vst/yabridge".source = "${pkgs.yabridge}/lib/yabridge";
  home.file.".local/share/applications/losslesscut-gpu.desktop" = {
    text = ''
      [Desktop Entry]
      Name=LosslessCut (No GPU)
      Comment=Audio/video cutter — NVIDIA/Wayland safe mode
      Exec=/etc/nixos/scripts/losslesscut-gpu %F
      Type=Application
      Categories=AudioVideo;Audio;Video;AudioVideoEditing;
      MimeType=audio/wav;audio/x-wav;audio/mpeg;audio/mp3;audio/flac;audio/ogg;video/mp4;video/x-matroska;video/webm;
      Icon=losslesscut
      Terminal=false
    '';
  };

  programs.noctalia-shell = {
    enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
      calendarSupport = true;
    };
    # settings usunięte — zarządzamy przez /etc/nixos/noctalia/*.json
  };




  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "0";
    NIXOS_OZONE_WL = "0";
    FLAKE = "/etc/nixos";
    MOZ_WEBRENDER = "0";
    
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
    obs-studio-plugins.wlrobs
    losslesscut-bin
    slurp

    # --- Communication ---
    telegram-desktop
    discord

    # --- AI / ML ---
    llama-cpp
    lmstudio

    # --- Productivity ---
    obsidian
    anki-bin

    croc

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
    navi
    (btop.override { cudaSupport = true;   }) 
    fastfetch
    ffmpeg
    atuin
    libnotify
    yazi

    
    python3Packages.faster-whisper
    python3Packages.sounddevice
    python3Packages.numpy

    xdotool
    ydotool

  ] ++ [
    # --- External flakes (not in nixpkgs) ---
    inputs.zen-browser.packages.${pkgs.system}.default
    inputs.kimi-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];





}
