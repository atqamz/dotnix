{ pkgs, ... }:
{
  # Global CLI utilities. Leaf tools only — no language toolchains (those live in
  # per-project nix devShells, see home/shell.nix), no system daemons, no GUI apps
  # (both still come from the host package manager until the box is full NixOS).
  home.packages = with pkgs; [
    glab          # GitLab CLI
    act           # run GitHub Actions locally
    skopeo        # inspect/copy container images
    lazygit       # git TUI
    lazydocker    # docker/podman TUI (point DOCKER_HOST at the podman socket for pods)
    btop          # resource monitor
    htop          # process viewer
    fastfetch     # system info
    age           # file encryption
    zip
    unzip
    p7zip
    wget
  ];

  # gh manages only non-secret config here; the auth token stays machine-local in
  # ~/.config/gh/hosts.yml (untouched by HM). git_protocol=ssh matches the
  # ssh-over-gpg-agent identity used everywhere else.
  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };

  # pass against the existing ~/.password-store (the pre-HM store lives there, not
  # the module's XDG default — pin it so `pass` keeps finding the 255 entries).
  programs.password-store = {
    enable = true;
    settings.PASSWORD_STORE_DIR = "$HOME/.password-store";
  };
}
