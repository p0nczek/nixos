# /etc/nixos/mikuri.nix
# ============================================
# KONFIGURACJA OD mikuri12 / my-nixos-config
# https://github.com/mikuri12/my-nixos-config
#
# ZMIANY względem oryginału:
# - USUNIĘTO: sddm.nix (używasz greetd)
# - USUNIĘTO: users.users.mikuri (masz swojego "shin")
# - USUNIĘTO: users.defaultUserShell (masz zsh)
# - USUNIĘTO: programs.fish.enable (masz zsh)
# - USUNIĘTO: locale/timezone (masz swoje de_DE / Europe/Berlin)
# - USUNIĘTO: xdg.portal (masz swoje z wlr)
# - USUNIĘTO: services.xserver.xkb (masz swoje xkb custom)
# - USUNIĘTO: pipewire/pulseaudio (masz swoje)
# - USUNIĘTO: hardware.graphics (masz swoje z nvidia)
# - USUNIĘTO: programs.niri.enable (masz włączone)
# - USUNIĘTO: nix.settings.experimental-features (masz w swoim)
# - ZOSTAWIONO: boot.plymouth + mikuboot, pakiety, programs, services
# ============================================

{ config, pkgs, lib, inputs, ... }:

{
  # --- Boot (kernel latest) ---
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # --- X11 (on włącza, Ty też masz włączone przez nvidia) ---
  services.xserver.enable = true;

  # --- Session variables (Qt Wayland) ---
  environment.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  # --- Programs ---
  programs.dconf.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  programs.gamemode.enable = true;
  programs.firefox.enable = true;

  # --- Services ---
  services.fwupd.enable = true;
  services.flatpak.enable = true;

  # --- Plymouth + mikuboot theme ---
  boot.plymouth = {
    enable = true;
    themePackages = [ pkgs.mikuboot ];
    theme = "mikuboot";
  };

  # ============================================
  # PAKIETY OD MIKURI
  # ============================================
  environment.systemPackages = with pkgs; [
    # --- Dev / Media ---
    vscodium
    gamescope
    gpu-screen-recorder
    yazi
    yt-dlp

    # --- Qt / KDE deps ---
    kdePackages.layer-shell-qt
    libsForQt5.qt5.qtmultimedia
    kdePackages.qtbase
    kdePackages.qtwayland
    kdePackages.qtmultimedia
    kdePackages.breeze
    kdePackages.breeze-gtk
    kdePackages.breeze-icons
    kdePackages.ark

    # --- Portals (on używa gnome+gtk, Ty masz wlr+gtk w swoim) ---
    # Te dodajemy bo niektóre programy mogą ich potrzebować
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
    xdg-desktop-portal-wlr
    xdg-desktop-portal

    # --- File manager ---
    nautilus

    # --- Music ---
    spicetify-cli
    spotify

    # --- Archivers ---
    p7zip
    unrar

    # --- Gaming ---
    heroic
    lutris
    wineWowPackages.stagingFull
    xorg.xvfb
    cemu

    # --- Wayland utils ---
    niri
    xwayland-satellite
    vulkan-tools
    wl-clipboard
    wayland-utils
    mesa
    cliphist

    # --- Browsers / Chat ---
    brave
    vesktop

    # --- Rice / Aesthetics ---
    cava
    nitch
    fastfetch

    # --- Git / Basics ---
    git
    vim
    wget

    # --- Theming ---
    dconf
    libsForQt5.qt5ct
    kdePackages.qt6ct
    kdePackages.qtwayland
    gsettings-qt
    nwg-look
    gsettings-desktop-schemas
    xsettingsd
    gtk-engine-murrine
    adwaita-icon-theme
    material-symbols
    adw-gtk3
    morewaita-icon-theme

    # --- Fonts ---
    noto-fonts
    noto-fonts-color-emoji
    hack-font

    # --- Icons ---
    papirus-icon-theme

    # --- Shell ---
    starship
    glib
    fish
    flatpak
  ];
}
