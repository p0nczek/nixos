{ pkgs, ... }:
{
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

home.sessionVariables = {
  MOZ_ENABLE_WAYLAND = "1";   # zamiast "0"
  NIXOS_OZONE_WL = "1";       # zamiast "0"
  # MOZ_WEBRENDER = "0";      # USUŃ tę linię całkowicie
  FLAKE = "/etc/nixos";
};

  home.sessionPath = [ "$HOME/.local/bin" ];

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
}
