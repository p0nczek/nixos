{ pkgs, ... }:
{
  home.packages = with pkgs; [
    llama-cpp
    lmstudio
    python3Packages.faster-whisper
    python3Packages.sounddevice
    python3Packages.numpy
    xdotool
    ydotool
  ];
}
