{config, ...}: let
  efiSysMountPoint = "/efi";
  efiSize = "300MiB";
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
    tmp.useTmpfs = true;
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
    device = config.viper.mainDisk;
    type = "disk";
    content = {
      type = "table";
      format = "gpt";
      partitions = [
        {
          name = "ESP";
          start = "1MiB";
          end = efiSize;
          bootable = true;
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = efiSysMountPoint;
          };
        }
        {
          name = "MAIN";
          start = efiSize;
          end = "100%";
          content = {
            type = "btrfs";
            extraArgs = ["-f"]; # Override existing partition
            subvolumes = let
              mountOptions = ["compress=zstd" "noatime"];
            in {
              "@nix" = {
                mountpoint = "/nix";
                inherit mountOptions;
              };
              "@var" = {
                mountpoint = "/var";
                inherit mountOptions;
              };
              "@ayats" = {
                mountpoint = "/home/ayats";
                inherit mountOptions;
              };
            };
          };
        }
      ];
    };
  };

  disko.devices.nodev."/" = {
    fsType = "tmpfs";
    mountOptions = [
      "size=2G"
      "defaults"
      "mode=0755"
    ];
  };
}
