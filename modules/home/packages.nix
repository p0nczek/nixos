{ pkgs, inputs, ... }:
{

  home.packages = with pkgs; [
    reaper renoise pavucontrol qpwgraph lsp-plugins pamixer playerctl
    wineWow64Packages.stable yabridge yabridgectl winetricks qjackctl

    mpv 
    obs-studio-plugins.wlrobs 
    losslesscut-bin 
    slurp

    telegram-desktop 
    #discord

    obsidian 
    anki-bin 
    croc 
    comma
    vesktop
    #betterdiscordctl

    nautilus p7zip unrar python3 eza bat fd ripgrep fzf zoxide navi
    (btop.override { cudaSupport = true; })
    fastfetch ffmpeg atuin libnotify yazi
  ] ++ [
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    #inputs.kimi-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
