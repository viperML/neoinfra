{
  pkgs,
  inputs,
  config,
  lib,
  self,
  ...
}: {
  time.timeZone = "Europe/Berlin";
  system.stateVersion = "22.05";
  system.configurationRevision = self.rev or null;
  environment.defaultPackages = [];

  environment.systemPackages = with pkgs; [
    htop
    jq
    # (pkgs.callPackage inputs.viperML-dotfiles.packages.${pkgs.system}.vshell.override)
  ];

  nix = {
    settings = {
      extra-experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    systemFeatures = [
      "nixos-test"
    ];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-old";
    };
  };

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
  sops.secrets."ssh_host_ecdsa_key" = {
    sopsFile = "${self}/secrets/sumati-ssh.yaml";
    mode = "600";
  };
  sops.secrets."ssh_host_ecdsa_key-cert-pub" = {
    sopsFile = "${self}/secrets/sumati-ssh.yaml";
    mode = "644";
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
    passwordAuthentication = false;
    extraConfig = ''
      HostKey ${config.sops.secrets."ssh_host_ecdsa_key".path}
      HostCertificate /var/lib/secrets/ssh_host_ecdsa_key-cert.pub
    '';
    hostKeys = [];
  };

  services.tailscale.enable = true;
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [22];
  networking.firewall.checkReversePath = "loose";
}
