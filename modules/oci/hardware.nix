let
  efiSysMountPoint = "/efi";
in {
  services.cloud-init = {
    enable = true;
    # config = builtins.readFile ./cloud-config.yaml;
    config =
      builtins.toJSON
      {
        disable_root = false;
        preserve_hostname = false;
        system_info = {
          distro = "nixos";
          network = {renderers = ["networkd"];};
        };
        cloud_init_modules = [
          # "migrator"
          "seed_random"
          "bootcmd"
          "write-files"
          # "update_hostname"
        ];
        cloud_config_modules = [
          "runcmd"
        ];
        cloud_final_modules = [
          "scripts-vendor"
          "scripts-per-once"
          "scripts-per-boot"
          "scripts-per-instance"
          "scripts-user"
          "power-state-change"
        ];
      };
    network.enable = true;
  };

  services.getty.autologinUser = "root";
  users.allowNoPasswordLogin = true;

  boot = {
    kernelParams = [
      "console=ttyS0"
      "console=tty1"
    ];
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 1;
      };
      efi = {
        inherit efiSysMountPoint;
        canTouchEfiVariables = true;
      };
    };
    initrd = {
      systemd.enable = true;
      availableKernelModules = ["xhci_pci"];
    };
  };

  systemd.network = {
    enable = true;
    networks.default = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "yes";
    };
  };
  networking = {
    useNetworkd = false;
    useDHCP = false;
  };

  services.qemuGuest.enable = true;

  disko.devices.disk."main" = {
    device = "/dev/sda";
    type = "disk";
    content = {
      type = "table";
      format = "gpt";
      partitions = [
        {
          name = "ESP";
          start = "1MiB";
          end = "300MiB";
          bootable = true;
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = efiSysMountPoint;
          };
        }
        {
          name = "root";
          start = "300MiB";
          end = "100%";
          part-type = "primary";
          bootable = true;
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        }
      ];
    };
  };
}
