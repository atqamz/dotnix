{ ... }:
{
  # Per-project nix devShells, auto-loaded on cd via .envrc (`use flake`).
  # nix-direnv caches the shell so re-entry is instant.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
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

    # Only user scripts on the global PATH. Language toolchains (go, bun, node,
    # rust, ...) come from per-project nix devShells (flake.nix + direnv), not
    # global installs — so GOPATH/BUN_INSTALL and their bin dirs are GONE.
    initExtra = ''
      export PATH="$HOME/.local/bin/scripts:$HOME/.local/bin:$HOME/bin:$PATH"

      # user drop-ins
      if [ -d ~/.bashrc.d ]; then
        for rc in ~/.bashrc.d/*; do [ -f "$rc" ] && . "$rc"; done
        unset rc
      fi

      # gpg pinentry tty fallback
      export GPG_TTY=$(tty)

      # ssh-agent
      if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)" > /dev/null
        ssh-add ~/.ssh/id_ed25519 2>/dev/null
      fi
    '';
  };
}
