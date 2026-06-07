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

    # Noctalia desktop shell & widgets
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
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
  };

  # ============================================================================
  #  OUTPUTS
  # ============================================================================
  outputs = inputs@{ nixpkgs, home-manager, noctalia, zen-browser, kimi-cli, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix

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
