{ pkgs, lib, ... }:
let
  niriSession = pkgs.writeShellScript "niri-session" ''
    export XKB_CONFIG_EXTRA_PATH=/etc/xkb
    exec niri
  '';
in
{
  programs.niri.enable = true;
  programs.xwayland.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${niriSession}";
        user = "greeter";
      };
      initial_session = {
        command = "${niriSession}";
        user = "shin";
      };
    };
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  security.pam.services.greetd.enableGnomeKeyring = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      niri = {
        default = lib.mkForce [ "wlr" "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast"   = [ "wlr" ];
        "org.freedesktop.impl.portal.Screenshot"   = [ "wlr" ];
        "org.freedesktop.impl.portal.Access"       = [ "gtk" ];
        "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      };
    };
  };

  services.gnome.evolution-data-server.enable = true;
  services.printing.enable = true;
  programs.nix-ld.enable = true;
}