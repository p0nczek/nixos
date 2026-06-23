# /etc/nixos/flake.nix
{
  description = "NixOS - shin + mikuri12 modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # --- Home Manager ---
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === MIKURI12 INPUTS ===
    mikuboot = {
      url = "gitlab:evysgarden/mikuboot";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-shell = {
      url = "github:Noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mango = {
      url = "github:DreamMaoMao/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elyprismlauncher.url = "github:ElyPrismLauncher/ElyPrismLauncher/10.0.2";
    # =======================
  };

  outputs = { self, nixpkgs, home-manager, mikuboot, noctalia-shell, quickshell, mango, elyprismlauncher, ... }@inputs:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };

      modules = [
        # --- Home Manager jako NixOS module ---
        home-manager.nixosModules.home-manager

        # --- Mikuboot Plymouth theme ---
        mikuboot.nixosModules.default

        # --- Mango (jego overlay) ---
        mango.nixosModules.mango

        # --- Mikuri config ---
        ./mikuri.nix

        # --- Twój główny config ---
        ./configuration.nix

        {
          # Home Manager integration
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";

          # Mango enable
          programs.mango.enable = true;

          # Jego pakiety z flake inputs
          environment.systemPackages = with nixpkgs.legacyPackages.${system}; [
            noctalia-shell.packages.${system}.default
            elyprismlauncher.packages.${system}.default
            quickshell.packages.${system}.default
          ];
        }
      ];
    };
  };
}
