{
  services.postgresql = {
    enable = true;

    initdbArgs = [
      "--locale=C"
      "--encoding=UTF8"
    ];
  };
}
