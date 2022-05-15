{
  pkgs,
  lib,
  ...
}: let
  metadata = pkgs.writers.makeScriptWriter {
    interpreter = (pkgs.python3.withPackages (pP: [pP.pyyaml])).outPath + "/bin/python3";
    check = pkgs.writeShellScript "check" ''
      ${pkgs.python3Packages.flake8}/bin/flake8 --show-source "$1"
    '';
  } "metadata" (builtins.readFile ./metadata.py);
in {
  systemd.services = {
    hcloud-metadata = {
      description = "Download cloud-init & hetzner network metadata";
      after = ["network-online.target"];
      requires = ["network-online.target"];
      serviceConfig.DynamicUser = "yes";
      serviceConfig.ExecStart = "${metadata}";
      serviceConfig.StandardOutput = "truncate:/etc/hcloud-metadata.json";
      wantedBy = ["multi-user.target"];
    };
    hcloud-userdata = {
      description = "Download cloud-init userdata";
      after = ["network-online.target"];
      requires = ["network-online.target"];
      serviceConfig.DynamicUser = "yes";
      serviceConfig.ExecStart = ''
        ${pkgs.curl}/bin/curl --fail -s http://169.254.169.254/hetzner/v1/userdata
      '';
      serviceConfig.StandardOutput = "truncate:/etc/hcloud-userdata";
      wantedBy = ["multi-user.target"];
    };
  };
}
