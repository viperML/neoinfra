{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = [pkgs.mosh];
  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedUDPPortRanges = [
    {
      from = 60000;
      to = 61000;
    }
  ];
  security.wrappers = {
    utempter = {
      source = "${pkgs.libutempter}/lib/utempter/utempter";
      owner = "root";
      group = "utmp";
      setuid = false;
      setgid = true;
    };
  };
}
