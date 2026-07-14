{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nh
    git
    jujutsu

    kitty
    micro

    ddcutil
    ddcui
    brightnessctl

    xwayland-satellite
    wl-clipboard
    wtype
    networkmanagerapplet

    flatpak
    appimage-run
    fuse
    fuse3
    nodejs_22

    nix-ld
    wayland
    libxkbcommon
    libGL

    jq

    android-tools
    adb-sync
    v4l-utils

    gpu-screen-recorder-gtk
    espeak-ng
    pipewire
    pipewire.jack

    wineWowPackages.wine-ge
  ];
}
