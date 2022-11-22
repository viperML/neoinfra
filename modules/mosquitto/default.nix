{...}: let
  port = 1883;
in {
  networking.firewall = {
    allowedTCPPorts = [port];
    allowedUDPPorts = [port];
  };

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        inherit port;
        users = {
          "guest" = {
            acl = ["readwrite #"];
            password = "hello-world-hello-world";
          };
        };
      }
    ];
  };
}
