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
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBMUWVVwPkeBBssbg+REsekNuKT0wxMByBk6UjrHlJ+4fIiYtHlCqRXPsfv92A35BPpIt84WgBr98JpjdTLKWM4U="
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
