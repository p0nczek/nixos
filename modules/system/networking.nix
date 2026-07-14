{ config, pkgs, ... }:

{

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.enableIPv6 = false;

   
}
