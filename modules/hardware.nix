{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: {
  time.timeZone = "Europe/Berlin";
  system.stateVersion = "21.11";
  system.configurationRevision = inputs.self.rev or null;
  environment.defaultPackages = [];
  environment.systemPackages = with pkgs; [
    htop
    fish
    vim
  ];

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    autoOptimiseStore = true;
  };

  networking = rec {
    hostName = "sumati";
    hostId = builtins.substring 0 8 (builtins.hashString "md5" hostName);
    useNetworkd = true;
    useDHCP = false;
    interfaces.ens3 = {
      useDHCP = true;
    };
  };

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "ext4";
    };

    "/" = {
      device = "tank/rootfs";
      fsType = "zfs";
    };
    "/nix" = {
      device = "tank/nix";
      fsType = "zfs";
    };
    "/var" = {
      device = "tank/var";
      fsType = "zfs";
    };
    "/secrets" = {
      device = "tank/secrets";
      fsType = "zfs";
    };
  };

  sops.age.keyFile = "/secrets/sumati.age";

  boot = {
    tmpOnTmpfs = true;
    supportedFilesystems = ["zfs"];
    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "virtio_pci"
      "sd_mod"
      "sr_mod"
    ];
    loader.grub = {
      enable = true;
      device = "/dev/sda";
      zfsSupport = true;
      configurationLimit = 10;
    };
    kernelPackages = pkgs.zfs.latestCompatibleLinuxPackages;
    zfs.enableUnstable = true;
    initrd.postDeviceCommands = lib.mkAfter ''
      zfs rollback -r tank/rootfs@empty
    '';
  };

  services.qemuGuest.enable = true;
}
