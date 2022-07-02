{
  config,
  pkgs,
  modulesPath,
  ...
}: {
  system.stateVersion = "22.05";

  time.timeZone = "UTC";

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        efiSysMountPoint = "/efi";
        canTouchEfiVariables = true;
      };
    };
    initrd = {
      systemd.enable = true;
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

  networking = rec {
    hostName = "kalypso";
    hostId = builtins.substring 0 8 (builtins.hashString "md5" hostName);
    useNetworkd = false;
    useDHCP = false;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/cloudimg-rootfs";
      fsType = "ext4";
    };
    "/efi" = {
      device = "/dev/disk/by-label/UEFI";
      fsType = "vfat";
    };
  };
}
