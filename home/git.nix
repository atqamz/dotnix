{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;

    signing = {
      key = "F1F60517602888C8D5E486EB8AD7D4A302EE6771";
      signByDefault = true;
    };

    # Freeform git config (was extraConfig + userName/userEmail, renamed to
    # settings in HM 26.05).
    settings = {
      user.name = "Atqa Munzir";
      user.email = "atqamz@gmail.com";

      gpg.program = "gpg";
      init.defaultBranch = "master";
      fetch.prune = true;
      tag.gpgsign = true;

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
