# libvirt + qemu/kvm + virt-manager — mirrors the Fedora `libvirt` role
# (qemu-kvm, virt-manager, edk2-ovmf, swtpm).
{ config, pkgs, lib, ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      ovmf.enable = true; # edk2 UEFI firmware for guests
      ovmf.packages = [ pkgs.OVMFFull.fd ];
      swtpm.enable = true; # software TPM for Win11 / measured-boot guests
    };
  };

  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    virt-manager
    qemu
  ];
}
