{lib, ...}: let
  ca_path = "ssh/ca.d";
in {
  users.users.admin = {
    name = "admin";
    isNormalUser = true;
    extraGroups = ["wheel"];
  };
  security.sudo.wheelNeedsPassword = false;
  nix.trustedUsers = ["@wheel"];
  services.getty.autologinUser = "admin";

  services.openssh.extraConfig = ''
    TrustedUserCAKeys /etc/${ca_path}/ssh_user_keys.pub
    AuthorizedPrincipalsFile /etc/${ca_path}/%u_principals
  '';

  environment.etc = {
    "${ca_path}/ssh_user_keys.pub" = {
      mode = "0444";
      text = lib.concatStringsSep "\n" [
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBP48bSdoBVw86DtnWzT8g2cl/5ML3vCPS5f88itOPqFrsUZ8dmftMsBG8iMAssvdK6qc9seabRL2/xc3r7Fjnhg="
      ];
    };
    "${ca_path}/admin_principals" = {
      mode = "0444";
      text = lib.concatStringsSep "\n" [
        "ayats"
        "admin"
      ];
    };
  };
}
