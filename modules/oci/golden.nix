{...}: {
  users.users.admin = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    createHome = true;
    password = "admin";
  };
}
