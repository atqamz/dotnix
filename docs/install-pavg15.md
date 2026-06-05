# pavg15 NixOS install runbook

Physical install. Run at the machine off a NixOS ISO. Nothing here is driven
remotely — partitioning and `nixos-install` happen at the keyboard.

## Disk facts (captured from live Fedora 44, 2026-06-05)

| Disk | Size | Contents | Action |
|------|------|----------|--------|
| `sda` | 931.5G | Windows: `sda1` MSR (16M), `sda2` NTFS 443G, `sda3` NTFS "New Volume" 488G | **NEVER TOUCH** |
| `nvme0n1` | 238.5G | Fedora: `p1` ESP 600M, `p2` /boot ext4 2G, `p3` btrfs 235.9G | **WIPE — install target** |

Firmware boot entries (efibootmgr) — for awareness, not action:
- `Boot0000 Windows` → ESP PARTUUID `b4e45a92…` which is **absent from both disks**.
  Windows bootloader ESP is orphaned; Windows likely already not booting. Its
  data on `sda2`/`sda3` is preserved (we never touch sda).
- `Boot0002 Ubuntu`, `Boot0005 debian` → stale (PARTUUIDs absent). Cleared by install.
- The Fedora ESP `nvme0n1p1` (`cc6b9069`) holds only `EFI/{BOOT,fedora}` — no
  `Microsoft` dir, so reformatting it cannot harm Windows boot.

> Sanity check at install time: `lsblk` must still show `sda` = 931.5G with three
> NTFS/MSR partitions and `nvme0n1` = 238.5G. If disk names shifted, STOP and
> re-identify before running any `mkfs`/`parted`.

## Pre-flight (on running Fedora, before rebooting to ISO)

1. **Push the flake** so the ISO can fetch it:
   ```
   cd ~/repo/dotnix && git push        # commits 3ac87a6 (system) + 2b3ffc2 (HM)
   ```
2. Back up anything unsaved on `nvme0n1p3` (the whole Fedora disk is wiped):
   `~`, `/etc` snippets, GPG keyring, ssh keys, pass store. Copy to sda data,
   external drive, or another host.
3. Note the real GPU bus IDs already in `modules/gpu.nix` (AMD `PCI:5:0:0`,
   NVIDIA `PCI:1:0:0`) — confirm unchanged with `lspci | grep -E 'VGA|3D'`.
4. Have the private `atqamz/secrets` repo + GPG key reachable (sops-nix wiring
   comes later; not needed for first boot).
5. Write the NixOS ISO (unstable, matching nixpkgs channel) to USB.

## Boot ISO + partition `nvme0n1` ONLY

Boot the ISO (firmware `Boot9999 USB Drive (UEFI)` or one-time boot menu).

```sh
# Re-confirm target before anything destructive:
lsblk
DISK=/dev/nvme0n1                 # NOT /dev/sda

# GPT: 1G ESP + rest btrfs. No separate /boot — systemd-boot reads kernels from ESP.
sudo parted $DISK -- mklabel gpt
sudo parted $DISK -- mkpart ESP fat32 1MiB 1GiB
sudo parted $DISK -- set 1 esp on
sudo parted $DISK -- mkpart nixos btrfs 1GiB 100%

sudo mkfs.fat -F32 -n EFI ${DISK}p1
sudo mkfs.btrfs -f -L nixos ${DISK}p2

# btrfs subvols (match the flake's hardware-configuration expectations)
sudo mount ${DISK}p2 /mnt
sudo btrfs subvolume create /mnt/root
sudo btrfs subvolume create /mnt/home
sudo btrfs subvolume create /mnt/nix
sudo umount /mnt

OPTS=compress=zstd:1,noatime
sudo mount -o subvol=root,$OPTS ${DISK}p2 /mnt
sudo mkdir -p /mnt/{home,nix,boot}
sudo mount -o subvol=home,$OPTS ${DISK}p2 /mnt/home
sudo mount -o subvol=nix,$OPTS  ${DISK}p2 /mnt/nix
sudo mount ${DISK}p1 /mnt/boot          # ESP mounted at /boot for systemd-boot
```

Swap: zram is configured in the flake (8G). No swap partition needed.

## Generate real hardware config

```sh
sudo nixos-generate-config --root /mnt
# This writes /mnt/etc/nixos/hardware-configuration.nix with REAL UUIDs/subvols.
```

The flake currently ships a PLACEHOLDER `hosts/pavg15/hardware-configuration.nix`
(by-label devices). Replace it with the generated one:

```sh
sudo nix-shell -p git --run '
  git clone https://github.com/atqamz/dotnix /mnt/root/dotnix
  cp /mnt/etc/nixos/hardware-configuration.nix \
     /mnt/root/dotnix/hosts/pavg15/hardware-configuration.nix
'
```

Diff the generated file against the placeholder; keep the generated
`fileSystems`/`boot.initrd` lines. Confirm `boot.loader.systemd-boot.enable`
and `boot.loader.efi.canTouchEfiVariables` are set (in `configuration.nix`); if
not, add them so the bootloader installs.

> If you edit the hardware file, commit it inside `/mnt/root/dotnix` (or carry
> the change back to the repo after first boot) so the flake stays reproducible.

## Install

```sh
cd /mnt/root/dotnix
sudo nixos-install --flake .#pavg15 --no-root-passwd
# Sets root via config; user atqa password:
sudo nixos-enter --root /mnt -c 'passwd atqa'
```

This pulls the full closure (≈3.6 GiB from cache + nvidia kmod/initrd compile —
expect a long first build, validated in dry-run earlier).

Reboot, remove USB.

## Post-boot (first login)

1. **GPU offload smoke test** — the Unity gate's residual risk:
   ```
   nvidia-offload glxinfo | grep -i renderer     # expect GTX 1650
   nvidia-offload unityhub                        # the make-or-break app
   ```
2. **Home-Manager** — source dotfiles, then apply:
   ```
   git clone https://github.com/atqamz/dotfiles ~/dotfiles   # symlink targets
   cd ~/repo/dotnix   # or wherever the flake lives post-install
   nix run home-manager -- switch --flake .#atqa
   ```
   `home/desktop-links.nix` symlinks `~/.config/{hypr,quickshell}` →
   `~/dotfiles/...` (live-edit). bash/tmux/git/readline are declarative.
   Confirm `git-credential-manager` resolved (pkg name unverified at write time).
3. Verify Hyprland session from tuigreet, quickshell bar renders, tailscale up,
   libvirtd, pipewire audio.
4. Bring `sops-nix` online when the first secret-consuming module lands; real
   secrets stay in private `atqamz/secrets`.

## Rollback

NixOS keeps prior generations in the bootloader menu. `nvme0n1` is independent of
`sda`, so Windows data is untouched regardless of outcome. Worst case: re-flash
Fedora to `nvme0n1` from backup.
