{ config, pkgs, lib, ... }:
{
  # --- Boot (UEFI -> systemd-boot) -------------------------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot"; # ESP mounted directly at /boot (single ESP + btrfs, no split /boot)

  # --- Identity / network ----------------------------------------------------
  networking.hostName = "pavg15";
  networking.networkmanager.enable = true; # matches Fedora; GNOME-free, nmcli/nmtui

  time.timeZone = "Asia/Jakarta"; # adjust if wrong
  i18n.defaultLocale = "en_US.UTF-8";

  # --- User -------------------------------------------------------------------
  users.users.atqa = {
    isNormalUser = true;
    description = "Atqa Munzir";
    extraGroups = [ "wheel" "networkmanager" "video" "libvirtd" "input" ];
    shell = pkgs.bash; # fish is installed as a pkg; switch here if you want it as login shell

    # Initial login password so a from-scratch nixos-anywhere install is reachable
    # without console rescue (the box is wifi-only + headless on first boot). sha-512
    # crypt hash, not plaintext -- safe to commit like /etc/shadow. mutableUsers stays
    # true, so `passwd` after first login persists and overrides this. CHANGE after login.
    #   regenerate: openssl passwd -6
    initialHashedPassword = "$6$juyklcj3FWrgjPeF$wXX4O3IT0I23hivDGQ0bauN94H7C3Bdqp5TIhSwvZQLw2yYPlXXX7Reo/rrj/LUXknnvMk2UamCiq0CG6/kHq/";

    # Classic-ssh allow-list = whatever keys are on github.com/atqamz.keys (every
    # device I own + my GPG [A] subkey served by gpg-agent). Pinned by sha256 so
    # eval stays reproducible; rebump when adding/removing a key on GitHub:
    #   curl -fsSL https://github.com/atqamz.keys | sha256sum
    openssh.authorizedKeys.keyFiles = [
      (builtins.fetchurl {
        url = "https://github.com/atqamz.keys";
        sha256 = "95283aa4b77d5ca9b711ae8b462e26f278dd89ba7fda69e5b4ffffdc4cdc3c1c";
      })
    ];
  };

  # Passwordless sudo for wheel matches the current pavg15 setup the agent relied on.
  security.sudo.wheelNeedsPassword = false;

  # --- Nix / flakes -----------------------------------------------------------
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "atqa" ];
  # Hyprland flake isn't on cache.nixos.org; its cachix serves binary hyprland +
  # deps so we don't compile from source. Required because we deliberately do NOT
  # make the hyprland input follow our nixpkgs (that would void this cache).
  nix.settings.substituters = [ "https://hyprland.cachix.org" ];
  nix.settings.trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  nixpkgs.config.allowUnfree = true; # nvidia driver + unityhub are unfree

  # --- SSH (key-only, matches ssh-server role) -------------------------------
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };
  networking.firewall.allowedTCPPorts = [ 22 ];

  # --- Tailscale --------------------------------------------------------------
  services.tailscale.enable = true;
  # Tailnet-identity SSH (no key mgmt) — the clean path for nixos-anywhere over the
  # tailnet. Needs a tailnet ACL granting ssh to this device; `tailscale up` applies
  # the flag (re-run `tailscale up` once after first switch if it was already up).
  services.tailscale.extraUpFlags = [ "--ssh" ];

  # IMPORTANT: keep in sync with the NixOS release you install from.
  system.stateVersion = "25.05";
}
