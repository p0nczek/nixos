{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    qmk
    pkgsCross.avr.buildPackages.gcc
    pkgsCross.avr.buildPackages.binutils
    pkgsCross.avr.avrlibc
    dfu-programmer
    avrdude
    gnumake
  ];

  services.udev.packages = [ pkgs.qmk-udev-rules ];
}
