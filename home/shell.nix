{ ... }:
{
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

    # User scripts + go/bun bins. On NixOS the system PATH is HM/NixOS-managed,
    # so the Fedora __order_path / linuxbrew / dnf-precedence dance is GONE.
    sessionVariables = {
      GOPATH = "$HOME/go";
      BUN_INSTALL = "$HOME/.bun";
    };
    initExtra = ''
      export PATH="$HOME/.local/bin/scripts:$HOME/.local/bin:$HOME/bin:$HOME/go/bin:$HOME/.bun/bin:$PATH"

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

      # gemini api key from pass (graphify-sync, memory-stale-report, ad-hoc extract)
      if command -v pass >/dev/null 2>&1; then
        GEMINI_API_KEY="$(pass show dotfiles/api-key/gemini 2>/dev/null)"
        [ -n "$GEMINI_API_KEY" ] && export GEMINI_API_KEY || unset GEMINI_API_KEY
      fi
    '';
  };
}
