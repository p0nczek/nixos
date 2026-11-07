{
  description = "Czysty NixOS z Niri, Noctalia Shell i Kimi CLI";

  # ============================================================================
  #  INPUTS
  # ============================================================================
  inputs = {
    # Core
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager (follows nixpkgs to avoid duplicate evals)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
  url = "github:noctalia-dev/noctalia-shell/v4.7.7";
  # bez inputs.nixpkgs.follows
};

    # Zen Browser
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Kimi CLI (official MoonshotAI flake)
    kimi-cli = {
      url = "github:MoonshotAI/kimi-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-cli = {
      url = "github:nix-community/nixos-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    qmk_firmware = {
      url = "github:qmk/qmk_firmware/0.18.17";
      flake = false;
    };

    vicinae = {
        url = "github:vicinaehq/vicinae/0f439e139c53a96fe15f3a7286e7fe054e25ae1c";
        inputs.nixpkgs.follows = "nixpkgs";  
      };
      
      millennium = {
        url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
        inputs.nixpkgs.follows = "nixpkgs";  
      };
      
    
    
  };

  

  # ============================================================================
  #  OUTPUTS
  # ============================================================================
  outputs = inputs@{ nixpkgs, home-manager, noctalia, zen-browser, kimi-cli, nixos-cli, qmk_firmware, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix

          nixos-cli.nixosModules.nixos-cli

          # Home Manager as a NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.shin = import ./home.nix;
          }
        ];
      };
    };
}
