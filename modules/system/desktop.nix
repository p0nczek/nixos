{ pkgs, lib, ... }:
{
    

  programs.niri.enable = true;
  programs.xwayland.enable = true;

  
environment.sessionVariables = {
  WLR_NO_HARDWARE_CURSORS = "1";
  NIXOS_OZONE_WL = "1";
  MOZ_ENABLE_WAYLAND = "1";
};

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "sh -c 'export XKB_CONFIG_EXTRA_PATH=/etc/xkb; exec niri'";
        user = "shin";
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd \"sh -c 'export XKB_CONFIG_EXTRA_PATH=/etc/xkb; exec niri'\"";
        user = "greeter";
      };
    };
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
