{ pkgs, ... }:
{
  imports = [
    ./shell.nix
    ./packages.nix
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

  # Cursor theme. Fedora (sfx14) had only its system Adwaita fallback; a fresh
  # NixOS install ships no cursor theme at all, so Hyprland drew its built-in
  # fallback. Setting it here installs the package and exports XCURSOR_THEME /
  # HYPRCURSOR_THEME (the latter via hyprcursor.enable) into the HM session vars
  # the uwsm env file sources, so both hosts render the same cursor.
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    hyprcursor.enable = true;
  };

  # Let HM manage itself.
  programs.home-manager.enable = true;
}
