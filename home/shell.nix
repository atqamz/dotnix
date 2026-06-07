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

  # The sole gpg-agent owner (no system programs.gnupg.agent — see modules/apps.nix),
  # so exactly one systemd user agent writes ~/.gnupg/gpg-agent.conf and the socket.
  # One systemd-managed agent for both GPG and SSH. enableSshSupport points
  # SSH_AUTH_SOCK at the gpg-agent socket; the bash integration sets GPG_TTY and
  # runs `gpg-connect-agent updatestartuptty` — so the old manual GPG_TTY export
  # and per-shell `ssh-agent -s` spawn are both gone. The ssh identity IS the
  # personal GPG [A] auth subkey: sshKeys lists its keygrip, which HM writes to
  # ~/.gnupg/sshcontrol so gpg-agent serves it over the ssh socket. No private
  # key file is placed on disk (the on-disk id_ed25519 was retired).
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;

    # Keygrip of the F1F60517 [A] auth subkey (gpg --with-keygrip -K). Listing it
    # here is the declarative equivalent of appending to ~/.gnupg/sshcontrol.
    sshKeys = [ "62863EC569FAA8E57719ECB56BA3571EA5695DFF" ];

    # Qt pinentry: Hyprland already pulls Qt (quickshell/alacritty), and unlike
    # gnome3 it needs no gcr/D-Bus prompter to break. pinentry-qt needs a Wayland
    # display and does NOT fall back to curses, so secret decryption is gated to
    # graphical-session.target (see home/sops.nix) where uwsm has exported
    # WAYLAND_DISPLAY. Over a display-less tailscale ssh, prefer a cached
    # passphrase (24h TTL below) or run gpg with --pinentry-mode loopback.
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

  programs.bash = {
    enable = true;
    initExtra = ''
      # Fedora ships the prompt, colors, and completion in /etc/bashrc; source it
      # when present (no-op on NixOS, which wires bash up its own way).
      [ -f /etc/bashrc ] && . /etc/bashrc

      # ssh served by gpg-agent (enable-ssh-support): set the socket if no graphical
      # session manager already exported it (e.g. a bare tty login).
      if [ -z "$SSH_AUTH_SOCK" ] && command -v gpgconf >/dev/null 2>&1; then
        export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
      fi
    '';
  };

  # Public half of the gpg [A] auth subkey. ssh's `IdentityFile ~/.ssh/id_ed25519`
  # (with IdentitiesOnly) resolves this .pub and asks gpg-agent for the matching
  # private. Public material, so a plain home.file in the store is fine — no sops.
  home.file.".ssh/id_ed25519.pub".text =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOo5r0biuWxR3He8lNwmkM7Z49mFJZZv4e90ohoIPDX7 atqamz@gmail.com\n";
}
