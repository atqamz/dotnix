{ ... }:
{
  imports = [
    ./shell.nix
    ./tmux.nix
    ./git.nix
    ./desktop-links.nix
  ];

  home.username = "atqa";
  home.homeDirectory = "/home/atqa";

  # Bump only after reading the HM release notes for the target version.
  home.stateVersion = "25.05";

  # Let HM manage itself.
  programs.home-manager.enable = true;
}
