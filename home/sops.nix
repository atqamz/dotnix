{ config, pkgs, lib, inputs, ... }:
let
  # The secrets repo is cloned (manually, over HTTPS+PAT) before the first switch;
  # it lives OUTSIDE this flake tree, so reference each file as a runtime STRING
  # path (not a nix path literal). A literal would be copied into the world-readable
  # /nix/store and, worse, rejected by pure-eval ("absolute path forbidden"). A
  # string is read by sops-install-secrets at activation, so nothing is staged and
  # the username is not hardcoded. validateSopsFiles must be off because the files
  # are not in the store for the eval-time envelope check.
  secretsDir = "${config.home.homeDirectory}/repo/secrets";

  # Armored GPG secret keys placed by sops, then imported into ~/.gnupg by the
  # gpg-import-keys unit below. The SOPS *root* key (F1F60517) is bootstrapped
  # manually (outer gpg --symmetric wrapper) and is NOT in this list.
  gpgKeys = [ "blankon" "deploy-yes2games" "deploy-hagegames" "password-store" ];

  importScript = pkgs.writeShellScript "gpg-import-keys" ''
    set -euo pipefail
    export GNUPGHOME="$HOME/.gnupg"
    install -d -m700 "$GNUPGHOME"
    for key in ${lib.escapeShellArgs (map (n: config.sops.secrets.${n}.path) gpgKeys)}; do
      if [ -r "$key" ]; then
        # --batch: silent, no passphrase prompt at import; idempotent across logins
        # (gpg dedupes by fingerprint). Passphrase is only needed later, on use.
        ${pkgs.gnupg}/bin/gpg --batch --import "$key"
      else
        echo "gpg-import-keys: missing/unreadable $key" >&2
        exit 1
      fi
    done
  '';
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    # Every secret has two recipients (see secrets/.sops.yaml): this machine's
    # age key and the GPG primary. age is the headless path — sops-install-secrets
    # reads the plaintext key file with no pinentry, so the user service decrypts
    # at boot even with gpg locked (the bug that left ~/.ssh/* dangling each boot).
    # The age private key is machine-local plaintext (mode 600), never in any repo;
    # bootstrap it once with `age-keygen -o ~/.config/sops/age/keys.txt`.
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # GPG kept as the second recipient/decrypt path for redundancy and for
    # interactive use; age is tried first and succeeds without a display.
    gnupg.home = "${config.home.homeDirectory}/.gnupg";
    gnupg.sshKeyPaths = [ ];

    validateSopsFiles = false;
    defaultSopsFormat = "binary";

    secrets = {
      # The personal ssh identity is the gpg [A] auth subkey served by gpg-agent
      # (see home/shell.nix services.gpg-agent.sshKeys); no private key file is
      # placed on disk. The public half is declared in home/shell.nix as a plain
      # home.file (it is public, not a secret).

      # SSH yes2infra deploy key.
      "yes2infra_ed25519" = {
        sopsFile = "${secretsDir}/ssh/yes2infra_ed25519.sops.key";
        path = "${config.home.homeDirectory}/.ssh/yes2infra_ed25519";
        mode = "0600";
      };
      "yes2infra_ed25519_pub" = {
        sopsFile = "${secretsDir}/ssh/yes2infra_ed25519.sops.pub";
        path = "${config.home.homeDirectory}/.ssh/yes2infra_ed25519.pub";
        mode = "0644";
      };

      # SSH config / known_hosts / authorized_keys.
      "ssh_config" = {
        sopsFile = "${secretsDir}/ssh/config.sops.txt";
        path = "${config.home.homeDirectory}/.ssh/config";
        mode = "0600";
      };
      "ssh_known_hosts" = {
        sopsFile = "${secretsDir}/ssh/known_hosts.sops.txt";
        path = "${config.home.homeDirectory}/.ssh/known_hosts";
        mode = "0644";
      };
      "ssh_authorized_keys" = {
        sopsFile = "${secretsDir}/ssh/authorized_keys.sops.txt";
        path = "${config.home.homeDirectory}/.ssh/authorized_keys";
        mode = "0644";
      };

      # Armored GPG secret keys. No explicit path: they land at the default
      # symlink path (~/.config/sops-nix/secrets/<name>) and gpg-import-keys
      # imports them from there.
      "blankon".sopsFile = "${secretsDir}/gpg/blankon.sops.asc";
      "deploy-yes2games".sopsFile = "${secretsDir}/gpg/deploy-yes2games.sops.asc";
      "deploy-hagegames".sopsFile = "${secretsDir}/gpg/deploy-hagegames.sops.asc";
      "password-store".sopsFile = "${secretsDir}/gpg/password-store.sops.asc";
    };
  };

  # sops-install-secrets makes a missing parent dir 0751 (MkdirAll); OpenSSH
  # StrictModes rejects keys under a group/other-accessible ~/.ssh. Pre-create it
  # 0700 so MkdirAll finds it and never downgrades. entryAfter writeBoundary is
  # required: a bare activation string sorts as entryAnywhere and may run before
  # the boundary where HM forbids writes.
  home.activation.ensureSshDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run install -d -m700 "$HOME/.ssh"
  '';

  # The module wires sops-nix.service to graphical-session-pre.target whenever
  # gnupg.home is set. Under uwsm that target activates BEFORE the compositor
  # finalizes WAYLAND_DISPLAY, so gpg-agent could be asked to unlock the key with
  # no display for pinentry-qt. Pin it to graphical-session.target instead, which
  # uwsm only reaches after `uwsm finalize` exports WAYLAND_DISPLAY.
  systemd.user.services.sops-nix.Install.WantedBy = lib.mkForce [ "graphical-session.target" ];

  # Import the armored GPG secret keys into ~/.gnupg once per login, after sops
  # has placed them. After+Requires order it; WantedBy only pulls it in.
  systemd.user.services.gpg-import-keys = {
    Unit = {
      Description = "Import sops-provided GPG secret keys into ~/.gnupg";
      After = [ "sops-nix.service" ];
      Requires = [ "sops-nix.service" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${importScript}";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
