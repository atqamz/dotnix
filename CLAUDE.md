# dotnix — NixOS config conventions

Declarative NixOS, personal laptops. Successor to `atqamz/dotmachines`
(Ansible/Fedora) + `atqamz/dotfiles` (GNU Stow). pavg15 only for now.

## Constraints

- **Flakes only.** Pin via `flake.lock`. No channels, no `nix-env -i`.
- **Public repo — no secrets here.** Nix store world-readable → anything in a
  `.nix` is published. Real secrets in private `atqamz/secrets` (SOPS, GPG root
  of trust `F1F60517602888C8D5E486EB8AD7D4A302EE6771`). Bridge via **sops-nix**:
  commit encrypted blobs, decrypt with that key.
- **Never inline a secret** — passwords (`hashedPasswordFile`, not
  `hashedPassword`), SSH/GPG keys, Tailscale auth keys, WARP/wireguard keys, API
  tokens, WiFi PSKs. Never a secret as derivation build input.
- **pavg15 only.** sfx14 stays Fedora until pavg15 daily-driven ~2wk + judged.
  No speculative sfx14 host config.
- **sda = Windows/data.** Install repartitions nvme0n1 only. Never touch sda.

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

- One concern per `modules/` module. Host-specific bits →
  `hosts/<host>/configuration.nix`.
- New host: add `hosts/<host>/`, generate its `hardware-configuration.nix` on
  the box, add `nixosConfigurations.<host>` output in `flake.nix`.
- Comments explain WHY a knob is set (driver quirk, hardware bus id), not what
  the option does.
- Verify before done: `nix flake check`, then
  `nixos-rebuild build --flake .#<host>`. Parse-only
  (`nix-instantiate --parse`) ≠ verification — option/package names confirm only
  on real eval/build.

## Adding a package

1. System-wide → `environment.systemPackages` in matching `modules/*.nix`.
2. Per-host only → that host's `configuration.nix`.
3. Program with NixOS module (`programs.*`/`services.*`) → prefer module over
   raw package + manual config.

## Adding a secret

Companion `secrets` repo, NOT here. Reference via sops-nix
(`sops.secrets.<name>` → `config.sops.secrets.<name>.path`). Repo only ever
holds encrypted `.sops.*` output.
