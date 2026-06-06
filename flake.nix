{
  description = "NixOS config for pavg15 (HP Pavilion Gaming 15) — full-NixOS pilot";

  inputs = {
    # Bleeding-edge to match the Fedora COPR Hyprland/quickshell currency.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Hyprland from upstream flake — pinned via flake.lock, no Qt-conflict roulette.
    hyprland.url = "github:hyprwm/Hyprland";

    # Home-Manager — standalone user-env flake, pinned to the 26.05 stable
    # branch (stable module API; packages still come from unstable nixpkgs via
    # follows). Single nixpkgs pin.
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Secret decryption at HM activation. Secrets themselves live in the private
    # atqamz/secrets repo (cloned to ~/repo/secrets), referenced by sops.nix as
    # runtime path strings — NOT a flake input, so eval/lock never needs them.
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Declarative disk partitioning — enables a fully-remote reproducible reinstall
    # via nixos-anywhere. disko owns the fileSystems (see hosts/pavg15/disk.nix).
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, hyprland, home-manager, ... }@inputs: {
    nixosConfigurations.pavg15 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        inputs.disko.nixosModules.disko
        ./hosts/pavg15/disk.nix
        ./hosts/pavg15/hardware-configuration.nix
        ./hosts/pavg15/configuration.nix
        ./modules/gpu.nix
        ./modules/desktop.nix
        ./modules/apps.nix
        ./modules/virtualisation.nix
      ];
    };

    # Standalone HM env — apply with: home-manager switch --flake .#atqa
    homeConfigurations.atqa = home-manager.lib.homeManagerConfiguration {
      # import (not legacyPackages) so allowUnfree applies — standalone HM has no
      # system nixpkgs.config to inherit; bare legacyPackages would reject unfree.
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      extraSpecialArgs = { inherit inputs; };
      modules = [ ./home/atqa.nix ];
    };
  };
}
