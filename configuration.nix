{ config, pkgs, lib, inputs, ... }:
let
  betterdiscord-asar = pkgs.fetchurl {
    url = "https://github.com/BetterDiscord/BetterDiscord/releases/latest/download/betterdiscord.asar";
    sha256 = "sha256-fKOWQWjKJd9qUZbNmKrmj2JgTdmecmlxs1YR+WniZD4=";
  };

  discord-with-bd = pkgs.discord.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      CORE="$out/opt/Discord/modules/discord_desktop_core"
      install -Dm444 ${betterdiscord-asar} "$out/opt/Discord/betterdiscord.asar"
      echo "require('$out/opt/Discord/betterdiscord.asar');" > "$CORE/index.js.new"
      cat "$CORE/index.js" >> "$CORE/index.js.new"
      mv "$CORE/index.js.new" "$CORE/index.js"
    '';
  });
in
{


  # Managed by the `nn` helper (updates label + git commit). Do not edit manually.
  system.nixos.label = "nixos-cli_";
  
  environment.systemPackages = [ discord-with-bd ];

  imports = [
    ./hardware-configuration.nix
    ./modules/system/xkb.nix
    ./modules/system/boot.nix
    ./modules/system/networking.nix
    ./modules/system/locale.nix
    ./modules/system/nix-settings.nix
    ./modules/system/nvidia.nix
    ./modules/system/audio.nix
    ./modules/system/desktop.nix
    ./modules/system/flatpak.nix
    ./modules/system/steam-obs.nix
    ./modules/system/users.nix
    ./modules/system/packages.nix
    ./modules/system/qmk.nix
    #./modules/system/vm.nix

  ];


  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";

  system.stateVersion = "25.11";
}
