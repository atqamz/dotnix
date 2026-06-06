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
    # SSH key restore is still handled out-of-band (your secrets repo), not here.
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

  # IMPORTANT: keep in sync with the NixOS release you install from.
  system.stateVersion = "25.05";
}
