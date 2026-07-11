{ pkgs, ... }:
{
  users.users.root.hashedPassword = "!";

  users.users.shin = {
    isNormalUser = true;
    description = "shin";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "audio" "i2c" "video" ];
    packages = with pkgs; [];
  };

  programs.zsh.enable = true;
}
