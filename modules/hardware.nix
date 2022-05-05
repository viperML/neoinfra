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
    jq
    inputs.viperML-dotfiles.packages.${pkgs.system}.vshell
  ];

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    autoOptimiseStore = true;
    systemFeatures = [
      "nixos-test"
    ];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-old";
    };
  };

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
    "/secrets" = {
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
    kernel.sysctl = {
      "vm.swappiness" = 10;
    };
  };

  services.qemuGuest.enable = true;

  sops.age = {
    keyFile = "/secrets/sumati.age";
    sshKeyPaths = [];
  };
  sops.gnupg.sshKeyPaths = [];
  sops.defaultSopsFile = ../secrets/sumati.yaml;

  # SSH Config

  sops.secrets."ssh_host_key" = {
    mode = "600";
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
    passwordAuthentication = false;
    hostKeys = [
      {
        path = config.sops.secrets."ssh_host_key".path;
        type = "ed25519";
      }
    ];
  };
  systemd.services.sshd = {
    after = ["tailscaled.service"];
    preStart = lib.mkAfter "${pkgs.coreutils}/bin/sleep 5";
  };
  services.tailscale.enable = true;
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [22];
}
