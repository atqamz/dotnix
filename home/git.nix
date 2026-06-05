{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = "Atqa Munzir";
    userEmail = "atqamz@gmail.com";

    signing = {
      key = "F1F60517602888C8D5E486EB8AD7D4A302EE6771";
      signByDefault = true;
    };

    extraConfig = {
      gpg.program = "gpg";
      init.defaultBranch = "master";
      fetch.prune = true;
      tag.gpgsign = true;

      # Git Credential Manager — store secrets in the GPG-backed pass DB.
      # NOTE: on Fedora this was /usr/local/bin/git-credential-manager; on NixOS
      # it comes from the git-credential-manager package on PATH.
      credential = {
        credentialStore = "gpg";
        helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
      };
      "credential \"https://dev.azure.com\"".useHttpPath = true;

      # Always reach GitHub over SSH even when a URL is given as HTTPS.
      "url \"git@github.com:\"".insteadOf = "https://github.com/";
    };
  };
}
