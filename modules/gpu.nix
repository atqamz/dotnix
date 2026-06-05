# NVIDIA GTX 1650 (Turing TU117M) + AMD Renoir iGPU — PRIME render offload.
# iGPU drives the desktop; the dGPU is woken only for offloaded apps (Unity).
# Bus IDs discovered on pavg15 2026-06-05:
#   NVIDIA  01:00.0  -> PCI:1:0:0
#   AMD     05:00.0  -> PCI:5:0:0
{ config, pkgs, lib, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam/Unity 32-bit GL bits
  };

  # The nvidia module only loads when "nvidia" is in videoDrivers, even on Wayland.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    # Turing supports the open kernel module, but the proprietary one is the
    # safer default for a GTX 1650. Flip to true only if you want to test it.
    open = false;

    nvidiaSettings = true;

    # Use the production driver pinned by nixpkgs. Override with a specific
    # version here if a regression bites.
    package = config.boot.kernelPackages.nvidiaPackages.production;

    # Offload: desktop on amdgpu, dGPU on demand. enableOffloadCmd installs the
    # `nvidia-offload` wrapper (sets __NV_PRIME_RENDER_OFFLOAD + GLX vendor).
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      amdgpuBusId = "PCI:5:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    powerManagement.enable = false; # enable only if you hit suspend/resume GPU issues
  };

  # Launch Unity (or any GL app) on the GTX 1650 via:  nvidia-offload unityhub
  # Equivalent to the env vars used in the Phase-0 probe:
  #   __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia
}
