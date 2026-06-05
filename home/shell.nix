{ pkgs, ... }:
{
  # User scripts on PATH (was the Fedora initExtra export). Language toolchains
  # come from per-project nix devShells, not the global PATH.
  home.sessionPath = [
    "$HOME/.local/bin/scripts"
    "$HOME/.local/bin"
    "$HOME/bin"
  ];

  # Per-project nix devShells, auto-loaded on cd via .envrc (`use flake`).
  # nix-direnv caches the shell so re-entry is instant.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # One systemd-managed agent for both GPG and SSH. enableSshSupport points
  # SSH_AUTH_SOCK at the gpg-agent socket; the bash integration sets GPG_TTY and
  # runs `gpg-connect-agent updatestartuptty` — so the old manual GPG_TTY export
  # and per-shell `ssh-agent -s` spawn are both gone. ssh keys load on first
  # `ssh-add ~/.ssh/id_ed25519` and persist in ~/.gnupg/sshcontrol.
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;

    # Qt pinentry: Hyprland already pulls Qt (quickshell/alacritty), and unlike
    # gnome3 it needs no gcr/D-Bus prompter to break. Modern pinentry-qt is the
    # upstream Wayland-native pick and falls back to curses when there is no
    # display (e.g. over tailscale ssh).
    pinentry.package = pkgs.pinentry-qt;

    # 24h passphrase cache (ported from the Fedora gpg-agent.conf). Both knobs
    # must be raised — maxCacheTtl is the absolute cap on defaultCacheTtl.
    defaultCacheTtl = 86400;
    maxCacheTtl = 86400;
    defaultCacheTtlSsh = 86400;
    maxCacheTtlSsh = 86400;
  };

  # Arrow keys do prefix history search (was ~/dotfiles/readline/.inputrc).
  programs.readline = {
    enable = true;
    bindings = {
      "\\e[A" = "history-search-backward";
      "\\e[B" = "history-search-forward";
    };
  };

  programs.bash.enable = true;
}
