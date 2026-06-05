# dotnix — NixOS config conventions

Declarative NixOS for personal laptops. Successor to `atqamz/dotmachines`
(Ansible/Fedora) and `atqamz/dotfiles` (GNU Stow). Currently pavg15 only.

## Constraints

- **Flakes only.** Pinned via `flake.lock`. No channels, no `nix-env -i`.
- **Public repo, no secrets here.** The Nix store is world-readable, so anything
  written into a `.nix` file is published. All real secrets live in the private
  companion repo `atqamz/secrets` (SOPS, GPG root of trust
  `F1F60517602888C8D5E486EB8AD7D4A302EE6771`). Bridge to NixOS via **sops-nix**:
  commit encrypted blobs, decrypt at activation into `/run/secrets`.
- **Never inline a secret** — passwords (`hashedPasswordFile`, not
  `hashedPassword`), SSH/GPG keys, Tailscale auth keys, WARP/wireguard keys, API
  tokens, WiFi PSKs. Never pass a secret as a derivation build input.
- **pavg15 only for now.** sfx14 stays on Fedora until pavg15 is daily-driven
  ~2 weeks and judged. Don't add sfx14 host config speculatively.
- **sda is Windows/data.** Install repartitions nvme0n1 only — never touch sda.

## Layout

```
flake.nix                    # inputs: nixpkgs unstable + hyprland flake
hosts/<host>/
  configuration.nix          # boot, user, network, ssh, tailscale, nix
  hardware-configuration.nix  # generated per host (nixos-generate-config)
modules/                     # cross-host reusable modules
  gpu.nix desktop.nix apps.nix virtualisation.nix
```

## Conventions

- One concern per module under `modules/`. Host-specific bits stay in
  `hosts/<host>/configuration.nix`.
- New host: add `hosts/<host>/`, generate its `hardware-configuration.nix` on
  the box, add a `nixosConfigurations.<host>` output in `flake.nix`.
- Comments explain why a knob is set (driver quirk, hardware bus id), not what
  the option does.
- Verify before claiming done: `nix flake check`, then
  `nixos-rebuild build --flake .#<host>`. Parse-only (`nix-instantiate --parse`)
  is not verification — option/package names only confirm on real eval/build.

## When adding a package

1. System-wide → `environment.systemPackages` in the matching `modules/*.nix`.
2. Per-host only → that host's `configuration.nix`.
3. A program with a NixOS module (`programs.*`/`services.*`) → prefer the module
   over raw package + manual config.

## When adding a secret

In the companion `secrets` repo, NOT here. Then reference via sops-nix
(`sops.secrets.<name>` → `config.sops.secrets.<name>.path`). The repo only ever
holds encrypted `.sops.*` output.
