{
  config,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  services.cloud-init = {
    enable = true;
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
    # BOOT_IMAGE=(hd0,gpt2)/vmlinuz-5.15.0-105.125.6.2.1.el9uek.x86_64 root=/dev/mapper/ocivolume-root ro crashkernel=1G-4G:192M,4G-64G:256M,64G-:512M LANG=en_US.UTF-8 console=tty0 console=ttyS0,115200 rd.luks=0 rd.md=0 rd.dm=0 rd.lvm.vg=ocivolume rd.lvm.lv=ocivolume/root rd.net.timeout.dhcp=10 rd.net.timeout.carrier=5 netroot=iscsi:169.254.0.2:::1:iqn.2015-02.oracle.boot:uefi rd.iscsi.param=node.session.timeo.replacement_timeout=6000 net.ifnames=1 nvme_core.shutdown_timeout=10 ipmi_si.tryacpi=0 ipmi_si.trydmi=0 libiscsi.debug_libiscsi_eh=1 loglevel=4 crash_kexec_post_notifiers
    kernelParams = [
      "loglevel=7"
      "console=tty0"
      "console=ttyS0,115200"
    ];
    kernelModules = ["kvm-amd"];
    initrd = {
      availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
      ];
      kernelModules = [
        "dm-snapshot"
      ];
      systemd = {
        enable = true;
        emergencyAccess = true;
      };
      services = {
        lvm.enable = true;
      };
    };
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 1; # can't use the boot menu anyways
      };
      efi = {
        # efiSysMountPoint = "";
        canTouchEfiVariables = true;
      };
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

  # disko.devices.disk."main" = {
  #   device = config.viper.mainDisk;
  #   type = "disk";
  #   content = {
  #     type = "table";
  #     format = "gpt";
  #     partitions = [
  #       {
  #         name = "ESP";
  #         start = "1MiB";
  #         end = efiSize;
  #         bootable = true;
  #         content = {
  #           type = "filesystem";
  #           format = "vfat";
  #           mountpoint = efiSysMountPoint;
  #         };
  #       }
  #       {
  #         name = "MAIN";
  #         start = efiSize;
  #         end = "100%";
  #         content = {
  #           type = "btrfs";
  #           extraArgs = ["-f"]; # Override existing partition
  #           subvolumes = let
  #             mountOptions = ["compress=zstd" "noatime"];
  #           in {
  #             "@nix" = {
  #               mountpoint = "/nix";
  #               inherit mountOptions;
  #             };
  #             "@var" = {
  #               mountpoint = "/var";
  #               inherit mountOptions;
  #             };
  #             "@ayats" = {
  #               mountpoint = "/home/ayats";
  #               inherit mountOptions;
  #             };
  #           };
  #         };
  #       }
  #     ];
  #   };
  # };

  # disko.devices.nodev."/" = {
  #   fsType = "tmpfs";
  #   mountOptions = [
  #     "size=2G"
  #     "defaults"
  #     "mode=0755"
  #   ];
  # };
}
