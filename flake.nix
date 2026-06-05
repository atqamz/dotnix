{
  description = "NixOS config for pavg15 (HP Pavilion Gaming 15) — full-NixOS pilot";

  inputs = {
    # Bleeding-edge to match the Fedora COPR Hyprland/quickshell currency.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Hyprland from upstream flake — pinned via flake.lock, no Qt-conflict roulette.
    hyprland.url = "github:hyprwm/Hyprland";

    # Home-Manager — standalone user-env flake. Single nixpkgs pin via follows.
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, hyprland, home-manager, ... }@inputs: {
    nixosConfigurations.pavg15 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
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
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = { inherit inputs; };
      modules = [ ./home/atqa.nix ];
    };
  };
}
