{...}: {
  documentation.enable = false;
  environment.defaultPackages = [];
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
  ];
  time.timeZone = "UTC";
  nix.settings = {
    extra-experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = [
      "https://viperml.cachix.org"
    ];
    extra-trusted-public-keys = [
      "viperml.cachix.org-1:qZhKBMTfmcLL+OG6fj/hzsMEedgKvZVFRRAhq7j8Vh8="
    ];
  };
  users.mutableUsers = false;
}
