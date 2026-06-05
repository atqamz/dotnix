{
  description = "NixOS config for pavg15 (HP Pavilion Gaming 15) — full-NixOS pilot";

  inputs = {
    # Bleeding-edge to match the Fedora COPR Hyprland/quickshell currency.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Hyprland from upstream flake — pinned via flake.lock, no Qt-conflict roulette.
    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = { self, nixpkgs, hyprland, ... }@inputs: {
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
  };
}
