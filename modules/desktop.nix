# Hyprland + quickshell desktop, audio, fonts, login manager.
# Mirrors the Fedora `hyprland` + `greetd` + base-packages audio/fonts roles.
{ config, pkgs, lib, inputs, ... }:
{
  # --- Hyprland (from the flake input, pinned by flake.lock) ------------------
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };

  # --- Login: greetd + tuigreet launching Hyprland ---------------------------
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
      user = "greeter";
    };
  };

  # --- Audio: PipeWire stack (mirrors base-packages audio list) --------------
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # --- Bluetooth / printing / power ------------------------------------------
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.printing.enable = true;
  services.power-profiles-daemon.enable = true;
  services.udisks2.enable = true;

  # --- Fonts (mirrors fonts list) --------------------------------------------
  fonts.packages = with pkgs; [
    font-awesome
    jetbrains-mono
    rubik
    material-icons
    material-symbols # the Symbols variant; install the one your shell actually uses
  ];

  # --- Desktop / Wayland packages --------------------------------------------
  environment.systemPackages = with pkgs; [
    quickshell # nixpkgs build; swap for the quickshell flake if you need bleeding-edge
    # Qt runtime quickshell pulls in is handled by the quickshell pkg itself.
    hyprlock
    hypridle
    hyprpicker
    hyprsunset
    grim
    slurp
    swappy
    wl-clipboard
    cliphist
    wtype
    brightnessctl
    playerctl
    ddcutil
    pavucontrol
    gpu-screen-recorder
    alacritty
    fish
    pinentry-gnome3
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
