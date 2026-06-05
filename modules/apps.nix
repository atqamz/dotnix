# Userland packages: the validated Unity Hub, CLI tools, dev tooling.
# Mirrors base-packages `cli` + `unityhub` + `tui-tools` roles.
{ config, pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    # --- The Phase-0-validated piece -----------------------------------------
    # Same derivation that passed the gate via Determinate Nix (bubblewrap FHS).
    # Launch on the GTX 1650:  nvidia-offload unityhub
    unityhub

    # --- CLI (from base-packages cli list) -----------------------------------
    git
    git-lfs
    htop
    btop
    nvtopPackages.full
    p7zip
    fastfetch
    jq
    mpv
    v4l-utils
    tesseract
    grim
    slurp

    # --- Tooling that was via Homebrew on Fedora (opencode/rtk/sops) ----------
    sops
    # opencode: in nixpkgs as `opencode` (verify version); rtk has no nixpkgs
    # entry yet — keep on Homebrew or package as a flake input later.
    opencode

    # --- VM / remote ---------------------------------------------------------
    tigervnc
    opentofu
  ];

  # gpg-agent (with ssh support + pinentry-qt) is owned solely by Home Manager
  # (home/shell.nix services.gpg-agent). No system programs.gnupg.agent here:
  # two definitions would spawn two systemd user agents racing the same
  # ~/.gnupg/gpg-agent.conf and socket. pinentry-qt stays available system-wide
  # via modules/desktop.nix; gpg lands on PATH via HM programs.gpg.enable.
}
