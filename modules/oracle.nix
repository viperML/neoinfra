{
  config,
  pkgs,
  ...
}: let
  original = "/old-root";
in {
  system.stateVersion = "22.05";

  time.timeZone = "UTC";

  nix.settings = {
    extra-experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  boot = {
    kernelParams = [
      "console=ttyS0"
      "console=tty1"
    ];
    loader = {
      systemd-boot.enable = true;
      efi = {
        efiSysMountPoint = "/efi";
        canTouchEfiVariables = true;
      };
    };
    initrd = {
      # systemd.enable = true;
      availableKernelModules = ["xhci_pci" "virtio_pci" "usbhid"];
    };
  };

  systemd.network = {
    enable = true;
    networks.default = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "yes";
    };
  };

  services.qemuGuest.enable = true;

  networking = {
    useNetworkd = false;
    useDHCP = false;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  fileSystems = {
    "/" = {
      fsType = "tmpfs";
      device = "none";
      options = [
        "defaults"
        "size=2G"
        "mode=755"
      ];
    };
    ${config.boot.loader.efi.efiSysMountPoint} = {
      device = "/dev/disk/by-label/UEFI";
      fsType = "vfat";
    };
    ${original} = {
      device = "/dev/disk/by-label/cloudimg-rootfs";
      fsType = "ext4";
      neededForBoot = true;
      options = [
        "discard"
        "noatime"
      ];
    };
    "/nix" = {
      device = "${original}/nix";
      options = ["bind"];
      depends = [original];
    };
    "/var" = {
      device = "${original}/new-var";
      options = ["bind"];
      depends = [original];
    };
  };

  # Wipe leftovers of Ubuntu
  systemd.tmpfiles.rules = map (f: "R ${original}${f} - - - - -") [
    "/bin"
    "/boot"
    "/dev"
    "/efi"
    "/etc"
    "/home"
    "/lib"
    "/media"
    "/mnt"
    "/opt"
    "/proc"
    "/root"
    "/run"
    "/sbin"
    "/snap"
    "/srv"
    "/sys"
    "/tmp"
    "/usr"
    "/var"
  ];
}
