{
  pkgs,
  config,
  lib,
  self,
  ...
}: {
  system.stateVersion = "22.05";

  environment.systemPackages = with pkgs; [
    htop
    jq
    tmux
    step-cli
    # inputs.viperML-dotfiles.packages.${system}.fish
  ];

  # nix = {
  #   systemFeatures = [
  #     "nixos-test"
  #   ];
  # };

  sops.secrets."private_nixconf" = {
    owner = "root";
    group = "wheel";
    mode = "0440";
  };

  environment.etc."xdg/nix/nix.conf".source = config.sops.secrets."private_nixconf".path;

  networking = rec {
    hostName = "sumati";
    hostId = builtins.substring 0 8 (builtins.hashString "md5" hostName);
    useNetworkd = false;
    useDHCP = false;
  };

  systemd.network = {
    enable = true;
    networks.default = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "yes";
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
    "/var/lib/secrets" = {
      device = "tank/secrets";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/var/lib/docker" = {
      device = "tank/docker";
      fsType = "zfs";
    };
  };

  swapDevices = [
    {device = "/dev/disk/by-label/SWAP";}
  ];

  services.zfs.autoScrub = {
    enable = true;
    pools = ["tank"];
    interval = "weekly";
  };

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
      configurationLimit = 20;
    };
    kernelPackages = pkgs.zfs.latestCompatibleLinuxPackages;
    zfs.enableUnstable = true;
    initrd.postDeviceCommands = lib.mkAfter ''
      zfs rollback -r tank/rootfs@empty
    '';
    initrd.systemd.enable = true;
    kernel.sysctl = {
      "vm.swappiness" = 10;
    };
  };

  services.qemuGuest.enable = true;

  sops.age = {
    keyFile = "/var/lib/secrets/sumati.age";
    sshKeyPaths = [];
  };
  sops.gnupg.sshKeyPaths = [];
  sops.defaultSopsFile = "${self}/secrets/sumati.yaml";

  services.tailscale.enable = true;
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [22];
  networking.firewall.checkReversePath = "loose";
}
