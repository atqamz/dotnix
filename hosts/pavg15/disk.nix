# Declarative disk layout for pavg15 (disko). Single NVMe, GPT:
#   - 1G ESP (vfat) -> /boot
#   - rest btrfs, subvols root/home/nix, zstd:1 compression
#
# disko OWNS the fileSystems (by-partlabel), so hardware-configuration.nix carries
# only hardware bits and no fileSystems block. Fully-remote reproducible reinstall:
#   nix run github:nix-community/nixos-anywhere -- --flake .#pavg15 root@<host-or-tailscale-ip>
#
# NOTE: a machine partitioned by hand (no GPT partlabels) will NOT boot this config
# via an in-place `nixos-rebuild switch` until it is reinstalled by nixos-anywhere
# (which sets the disk-main-* partlabels) or relabelled with `sgdisk -c`.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "fmask=0022" "dmask=0022" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "root" = {
                mountpoint = "/";
                mountOptions = [ "compress=zstd:1" "noatime" ];
              };
              "home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd:1" "noatime" ];
              };
              "nix" = {
                mountpoint = "/nix";
                mountOptions = [ "compress=zstd:1" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
