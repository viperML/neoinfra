{lib, ...}: {
  options = {
    viper.mainDisk = lib.mkOption {
      default = "/dev/sda";
      type = lib.types.str;
    };
  };
}