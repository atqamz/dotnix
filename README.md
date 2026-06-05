# dotnix — full-NixOS config for pavg15

Declarative NixOS, intended successor to the Ansible/Fedora setup in
`atqamz/dotmachines` and the GNU Stow dotfiles in `atqamz/dotfiles`.
Targets **pavg15 only** (HP Pavilion Gaming 15). sfx14 stays on Fedora until
this is daily-driven for ~2 weeks and judged.

This exists because the Phase-0 Unity gate (decision record:
`dotmachines/docs/nixos-pavg15-unity-gate.md`) **passed**: `nixpkgs#unityhub`
launches, logs in, opens a Unity 6 project, and renders on the GTX 1650 — the
one thing that could have vetoed full NixOS.

## Layout

```
flake.nix                              # inputs: nixpkgs unstable + hyprland flake
hosts/pavg15/
  configuration.nix                    # boot, user, network, ssh, tailscale, nix
  hardware-configuration.nix           # PLACEHOLDER — regenerate on install
modules/
  gpu.nix                              # nvidia GTX 1650 + AMD PRIME offload
  desktop.nix                          # hyprland + quickshell + pipewire + greetd + fonts
  apps.nix                             # unityhub (validated), cli, sops, libvirt tools
  virtualisation.nix                   # libvirt + qemu/kvm + ovmf + swtpm
```

## Status of each piece

| Piece | State |
|---|---|
| All `.nix` files parse | **verified** (`nix-instantiate --parse`, 2026-06-05) |
| `nix flake check` / build | **NOT run** — option + package names unconfirmed until first build |
| `unityhub` derivation | **validated** via Determinate Nix on Fedora (build + GUI + GTX 1650 render) |
| nvidia PRIME on real NixOS | unverified — bus IDs are correct; offload behavior confirms on install |
| Hyprland + quickshell session | unverified — config written, not booted |
| `hardware-configuration.nix` | **placeholder** — MUST regenerate with `nixos-generate-config` |
| dotfiles / Home Manager | **not yet** — quickshell + dotfiles port is the next big chunk |

Package names to confirm on first build: `rubik`, `material-symbols`,
`material-icons`, `opencode`. `rtk` has no nixpkgs entry (keep on Homebrew or
package later).

## Residual risk carried from Phase 0

Unity rendered on the GTX 1650 via *Fedora's* NVIDIA GLX inside the FHS sandbox.
On NixOS the GLX comes from `hardware.nvidia` + the FHS env. Almost certainly
fine, but this is the one thing validated by proxy — confirm with
`nvidia-offload unityhub` after the first boot.

## Install outline (destructive — pavg15 nvme only)

1. Back up anything on pavg15's nvme. The `sda` NTFS partitions (Windows/data)
   are left untouched, but **do not** repartition `sda`.
2. Boot the NixOS installer USB (match the release to
   `system.stateVersion = "25.05"` in `configuration.nix`, or bump both).
3. Partition + format the nvme, mount under `/mnt`.
4. `nixos-generate-config --root /mnt`, then **replace**
   `hosts/pavg15/hardware-configuration.nix` with the generated one.
5. Clone this repo to `/mnt/etc/nixos` (or use `--flake`), then:
   `nixos-install --flake /mnt/etc/nixos#pavg15`
6. Reboot. Log in via greetd → Hyprland.
7. Verify: `nvidia-offload unityhub` renders on the GTX 1650; pipewire audio;
   libvirt; tailscale up.
8. Port dotfiles (stow or Home Manager) — separate step.

## Secrets

**This repo is public — no plaintext secret ever lands in a `.nix` file.**
Everything in the Nix store is world-readable, so a secret written inline ends
up published. Same rule `dotmachines` follows: encrypted material only.

- Real secrets live in the private companion repo `atqamz/secrets`
  (SOPS, GPG root of trust `F1F60517602888C8D5E486EB8AD7D4A302EE6771`).
- On NixOS the idiomatic bridge is **sops-nix** — commit encrypted blobs,
  decrypt at activation into `/run/secrets` (tmpfs, root-only). Add it as a
  flake input when the first secret-consuming module lands.
- Never inline: hashed/plain passwords (use `hashedPasswordFile`), SSH/GPG
  private keys, Tailscale auth keys, WARP/wireguard keys, API tokens, WiFi PSKs.
- Never pass a secret as a derivation build input or string interpolation — it
  lands in the store. sops-nix decrypts at runtime, not build time.

## Out-of-band (still manual, like the Ansible flow)

- SSH key + GPG identity restore from the private `secrets` repo.
- Tailscale auth (`tailscale up`).
- WARP: no native NixOS module — install via the FHS/AppImage path or skip.
