{ ... }:
{
  imports = [
    ./shell.nix
    ./tmux.nix
    ./git.nix
    ./desktop-links.nix
    ./sops.nix
  ];

  home.username = "atqa";
  home.homeDirectory = "/home/atqa";

  # Bump only after reading the HM release notes for the target version.
  home.stateVersion = "25.05";

  # HM is pinned to stable 26.05 but fed unstable nixpkgs (for current packages),
  # a deliberate mismatch — silence the release-skew warning.
  home.enableNixpkgsReleaseCheck = false;

  # Let HM manage itself.
  programs.home-manager.enable = true;
}
