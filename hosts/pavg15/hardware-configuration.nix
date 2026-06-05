# ============================================================================
#  PLACEHOLDER — REGENERATE THIS FILE ON THE REAL INSTALL.
#
#  Run `nixos-generate-config --root /mnt` from the NixOS installer AFTER
#  partitioning pavg15's target disk, then replace this file with the generated
#  one (keep the imports/bus-ids from the other modules).
#
#  The block below is a SCAFFOLD reflecting pavg15's CURRENT Fedora layout
#  (discovered 2026-06-05) so you know what you're working with. A fresh NixOS
#  install will repartition nvme0n1 and produce NEW UUIDs — do NOT trust the
#  fileSystems entries here verbatim.
#
#  Discovered layout (Fedora):
#    nvme0n1p1  600M  vfat   -> /boot/efi   (ESP)
#    nvme0n1p2    2G  ext4   -> /boot
#    nvme0n1p3  236G  btrfs  -> /  (subvol root) and /home (subvol home)
#    sda (931G)  ->  sda2/sda3 NTFS  (Windows / data — DO NOT touch)
#  Firmware: UEFI.  CPU: AMD Ryzen 5 4600H.
# ============================================================================
{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Typical for this NVMe + AMD APU box. nixos-generate-config will confirm.
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # --- REPLACE everything below from the generated config ---------------------
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos"; # placeholder
    fsType = "btrfs";
    options = [ "subvol=root" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/nixos"; # placeholder — same partition, subvol home
    fsType = "btrfs";
    options = [ "subvol=home" "compress=zstd" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT"; # placeholder (ext4 /boot)
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-label/EFI"; # placeholder (vfat ESP)
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };
  # ----------------------------------------------------------------------------

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
