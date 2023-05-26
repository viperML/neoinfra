{lib, ...}: {
  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    (lib.fileContents ../../terraform/oci/id.pub)
  ];
}
