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
  };
}
