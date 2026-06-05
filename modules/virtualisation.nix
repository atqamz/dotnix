# libvirt + qemu/kvm + virt-manager — mirrors the Fedora `libvirt` role
# (qemu-kvm, virt-manager, edk2-ovmf, swtpm).
{ config, pkgs, lib, ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      # OVMF (edk2 UEFI firmware) ships by default now — the qemu.ovmf submodule
      # was removed upstream, so we no longer set it explicitly.
      swtpm.enable = true; # software TPM for Win11 / measured-boot guests
    };
  };

  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    virt-manager
    qemu
  ];
}
