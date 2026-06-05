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

  # password-store (pass) — enable_password_store is true for pavg15.
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };
}
