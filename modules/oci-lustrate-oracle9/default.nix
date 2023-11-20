{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: let
  vgname = "ocivolume";
  oldroot = "/.oldroot";
in {
  imports = [
    ../oci
  ];

  fileSystems = {
    ${config.boot.loader.efi.efiSysMountPoint} = {
      device = "/dev/disk/by-partlabel/esp";
      fsType = "vfat";
      options = [
        "x-systemd.automount"
        "x-systemd.mount-timeout=15min"
        "umask=077"
      ];
    };

    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [
        "defaults"
        "size=500M"
        "mode=0755"
      ];
    };

    ${oldroot} = {
      device = "/dev/${vgname}/root";
      fsType = "xfs";
      options = [
        "defaults"
      ];
      neededForBoot = true;
    };

    "/nix" = {
      device = "${oldroot}/nix";
      options = ["bind"];
      depends = [oldroot];
    };

    "/home" = {
      device = "${oldroot}/home";
      options = ["bind"];
      depends = [oldroot];
      neededForBoot = true;
    };

    "/var" = {
      device = "${oldroot}/newvar";
      options = ["bind"];
      depends = [oldroot];
    };

    "/tmp" = {
      device = "${oldroot}/tmp";
      options = ["bind"];
      depends = [oldroot];
      neededForBoot = true;
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-partlabel/swap";
    }
  ];

  environment.etc."format".source = pkgs.writeShellScript "format" ''
    export PATH="${lib.makeBinPath (with pkgs; [gptfdisk parted dosfstools util-linux])}:''${PATH}"
    ${lib.fileContents ./partition.sh}
  '';

  systemd.tmpfiles.rules = builtins.map (d: "R ${oldroot}/${d} - - - - -") [
    "afs"
    "bin"
    "boot"
    "dev"
    "etc"
    "lib"
    "lib64"
    "media"
    "mnt"
    "opt"
    "proc"
    "root"
    "run"
    "sbin"
    "srv"
    "sys"
    "usr"
    "var"
    ".swapfile"
  ];
}
