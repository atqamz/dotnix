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
4. Have a GitHub PAT (or `gh auth login`) ready to clone the private
   `atqamz/secrets` repo over **HTTPS** at first boot — gpg-agent only starts
   serving the SSH identity (the GPG `[A]` auth subkey) once that key is imported,
   which happens during the first `home-manager switch`. Also have the
   outer GPG passphrase for `gpg/personal.asc.gpg`. sops-nix wiring already ships
   in the flake (`home/sops.nix`); secrets are restored during the first switch
   (see Post-boot).
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

Log in to a **graphical Hyprland session** at the machine (not a bare TTY): the
SOPS GPG key is unlocked through pinentry-qt, which needs a Wayland display.

1. **GPU offload smoke test** — the Unity gate's residual risk:
   ```
   nvidia-offload glxinfo | grep -i renderer     # expect GTX 1650
   nvidia-offload unityhub                        # the make-or-break app
   ```

2. **Bootstrap the SOPS root key BEFORE the first switch.** sops-nix decrypts at
   activation using the GPG key in `~/.gnupg`, so it must be imported and unlocked
   first. gpg-agent is not serving SSH yet (the personal SSH identity is the GPG
   `[A]` auth subkey, served only after this import) — clone the secrets repo over
   HTTPS (PAT / `gh auth login`), not SSH.

   Base NixOS ships no `gpg`/`gh`/`sops` and no pinentry, so run the whole
   bootstrap inside one ephemeral shell. **A piped `gpg --decrypt | gpg --import`
   does NOT work here:** the import side inherits the pipe as stdin, pinentry-curses
   can't grab a tty, and it dies with `Inappropriate ioctl for device`. Set
   `GPG_TTY`, decrypt to a tmpfs file, then import from that file:
   ```sh
   nix-shell -p gnupg pinentry-curses sops gh git
   # inside the shell:
   gh auth login                                              # browser/device, no PAT needed
   git clone https://github.com/atqamz/secrets ~/repo/secrets
   cd ~/repo/secrets

   # point gpg-agent at a pinentry that exists (the nix-shell one):
   mkdir -p ~/.gnupg && chmod 700 ~/.gnupg
   echo "pinentry-program $(command -v pinentry-curses)" > ~/.gnupg/gpg-agent.conf

   export GPG_TTY=$(tty)                                      # else pinentry-curses: Inappropriate ioctl
   umask 077
   gpg --pinentry-mode loopback -o /dev/shm/p.asc -d gpg/personal.asc.gpg   # outer AES256 passphrase on tty
   gpg --import /dev/shm/p.asc                                # "secret key imported"
   shred -u /dev/shm/p.asc
   echo 'F1F60517602888C8D5E486EB8AD7D4A302EE6771:6:' | gpg --import-ownertrust
   gpg -K                                                     # confirm: sec F1F60517... + ssb [E] + ssb [A]

   # Prime the key ITSELF: `gpg --import` caches only the wrapper passphrase, not
   # the imported key's own. Exercise it once so gpg-agent caches it (24h TTL)
   # before the switch, else sops-nix.service fires pinentry mid-activation:
   SOPS_GPG_EXEC=gpg sops -d ssh/yes2infra_ed25519.sops.key >/dev/null
   ```
   The hand-written `~/.gnupg/gpg-agent.conf` here is throwaway — the first
   `home-manager switch` replaces it with the declarative pinentry-qt config
   (see step 3's `-b backup`).

3. **Home-Manager** — source dotfiles, then apply. The first eval fetches
   `sops-nix` and writes its `flake.lock` entry (the lock has no sops-nix node yet
   — there is no nix on the Fedora host to run `nix flake lock`):
   ```
   git clone https://github.com/atqamz/dotfiles ~/dotfiles   # symlink targets
   cd ~/repo/dotnix   # or wherever the flake lives post-install
   nix run home-manager -- switch --flake .#atqa -b backup
   ```
   `-b backup` is REQUIRED on the first switch: `checkLinkTargets` aborts on any
   pre-existing file HM wants to manage. Two always collide — the stale
   `~/.config/hypr` dir and the throwaway `~/.gnupg/gpg-agent.conf` from step 2;
   `-b backup` moves each to `*.backup` and proceeds.
   On switch, `sops-nix.service` decrypts `ssh/*` to `~/.ssh` and places the
   armored `gpg/*` keys, which `gpg-import-keys.service` then imports into
   `~/.gnupg`. `home/desktop-links.nix` symlinks `~/.config/{hypr,quickshell}` →
   `~/dotfiles/...` (live-edit); bash/tmux/git/readline are declarative.
   Confirm `git-credential-manager` resolved (pkg name unverified at write time).

4. **Verify secrets + session.**
   ```
   systemctl --user status sops-nix.service gpg-import-keys.service  # active/exited, 0
   ssh-add -l                                                        # gpg-agent serves the [A] auth subkey
   ssh -T git@github.com                                             # auth via that subkey
   # If ssh-add says "Could not open a connection to your authentication agent",
   # SSH_AUTH_SOCK is unset (bare/non-login shell). Real Hyprland login exports it
   # (bashrc/uwsm env); in a stray shell: export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
   gpg -K                                                            # blankon/deploy-*/password-store present
   ls -ld ~/.ssh                                                     # drwx------ (0700), not 0751
   ```
   Verify Hyprland from tuigreet, quickshell bar renders, tailscale up, libvirtd,
   pipewire audio.

> **Steady-state:** secrets decrypt into `$XDG_RUNTIME_DIR` (tmpfs) and
> re-decrypt each login via `sops-nix.service`, pulled in by
> `graphical-session.target` (activated by uwsm — bare Hyprland leaves it dead).
> A non-interactive consumer that runs OUTSIDE a graphical login (e.g. a user
> timer doing `git push` over SSH) needs `users.users.atqa.linger = true` AND the
> key present — verify before relying on it.

> **uwsm env (SHIPPED in dotfiles).** Under uwsm, `hl.env(...)` in `hyprland.lua`
> does NOT reach the systemd/dbus activation environment, so user services don't
> inherit it. The dotfiles `uwsm` stow module now carries env in
> `~/.config/uwsm/{env,env-hyprland}`: Nvidia vars (`LIBVA_DRIVER_NAME`,
> `GBM_BACKEND`, `__GLX_VENDOR_LIBRARY_NAME`), `XDG_DATA_DIRS` (appended), `PATH`,
> and `SSH_AUTH_SOCK` (computed via `gpgconf --list-dirs agent-ssh-socket` → the
> gpg-agent ssh socket) in `env`; `HYPR*`/cursor vars in `env-hyprland`. Quickshell
> logout routes through `scripts/.../session-logout` (`uwsm stop` when uwsm-active,
> else `hyprctl dispatch exit`). Inert on sfx14 (launches Hyprland without uwsm).

## Rollback

NixOS keeps prior generations in the bootloader menu. `nvme0n1` is independent of
`sda`, so Windows data is untouched regardless of outcome. Worst case: re-flash
Fedora to `nvme0n1` from backup.
