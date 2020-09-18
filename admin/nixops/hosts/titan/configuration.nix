# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

rec {
  imports = [
      ../common.nix
      ../../modules/nix-conf.nix
      ../../modules/zfs.nix
      #(import <nur_dguibert/modules>).qemu-user
      #../../modules/wayland-nvidia.nix
    ];
  #nesting.clone = [
  #  {
  #    imports = [
  #      ../../modules/wayland-nvidia.nix
  #    ];
  #    boot.loader.grub.configurationName = "Wayland NVIDIA";
  #  }
  #];

  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "isci" "usbhid" "usb_storage" "sd_mod" "nvme" ];
  boot.kernelModules = [ "kvm-intel" ];

  #boot.zfs.extraPools = [ "st4000dm004-1" ];
  fileSystems."/"         = { device = "icybox1/local/root"; fsType = "zfs"; };
  fileSystems."/nix"      = { device = "icybox1/local/nix"; fsType = "zfs"; neededForBoot=true; };
  fileSystems."/root"     = { device = "icybox1/safe/home/root"; fsType = "zfs"; };
  fileSystems."/home/dguibert" = { device = "icybox1/safe/home/dguibert"; fsType = "zfs"; };
  fileSystems."/home/dguibert/Videos" = { device = "icybox1/safe/home/dguibert/Videos"; fsType = "zfs"; };
  fileSystems."/persist" = { device = "icybox1/safe/persist"; fsType = "zfs"; };
  fileSystems."/boot/efi" = { label = "EFI1"; fsType = "vfat"; };
  fileSystems."/tmp"      = { device="tmpfs"; fsType="tmpfs"; options= [ "defaults" "noatime" "mode=1777" "size=15G" ]; neededForBoot=true; };

  boot.kernelParams = [ "console=console" "console=ttyS1,115200n8"
    "resume=/dev/nvme0n1p1"
  ];
  swapDevices = [ { device="/dev/nvme0n1p1"; } ];

  nix.maxJobs = lib.mkDefault 8;
  nix.buildCores = lib.mkDefault 24;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev";
  console.earlySetup = true;
  console.useXkbConfig = true;

  networking.hostId="8425e349";
  networking.hostName = "titan";

  #qemu-user.aarch64 = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" "armv7l-linux" ];
  #boot.binfmt.registrations."aarch64-linux".preserveArgvZero=true;
  boot.binfmt.registrations."aarch64-linux".fixBinary=true;
  #boot.binfmt.registrations."armv7l-linux".preserveArgvZero=true;
  boot.binfmt.registrations."armv7l-linux".fixBinary=true;

  services.openssh.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_5_8;
  boot.extraModulePackages = [ pkgs.linuxPackages.perf ];
  boot.zfs.enableUnstable = true;
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?

  networking.useNetworkd = lib.mkForce false;
  networking.dhcpcd.enable = false;
  systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = [
    "" # clear old command
    "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --ignore eno1 --ignore eno2 --ignore enp0s29u1u1u3i5"
  ];
  systemd.network.netdevs."40-bond0" = {
    netdevConfig.Name = "bond0";
    netdevConfig.Kind = "bond";
    #[Bond]
    #Mode=active-backup
    #PrimaryReselectPolicy=always
    #PrimarySlave=enp3s0
    #TransmitHashPolicy=layer3+4
    #MIIMonitorSec=1s
    #LACPTransmitRate=fast

    bondConfig.Mode="802.3ad";
    #bondConfig.PrimarySlave="eno1";
  };
  systemd.network.networks."40-bond0" = {
    name = "bond0";
    DHCP = "yes";
    networkConfig.BindCarrier = "eno1 eno2";
  };
  systemd.network.networks."40-eno1" = {
    name = "eno1";
    DHCP = "no";
    networkConfig.Bond = "bond0";
    networkConfig.IPv6PrivacyExtensions = "kernel";
  };
  systemd.network.networks."40-eno2" = {
    name = "eno2";
    DHCP = "no";
    networkConfig.Bond = "bond0";
    networkConfig.IPv6PrivacyExtensions = "kernel";
  };

  # services.xserver.videoDrivers = [ "nvidia" ];
  #services.xserver.videoDrivers = [ "nvidiaLegacy340" ];
  ## [   13.576513] NVRM: The NVIDIA Quadro FX 550 GPU installed in this system is
  ##                NVRM:  supported through the NVIDIA 304.xx Legacy drivers. Please
  ##                NVRM:  visit http://www.nvidia.com/object/unix.html for more
  ##                NVRM:  information.  The 340.104 NVIDIA driver will ignore
  ##                NVRM:  this GPU.  Continuing probe...
  hardware.nvidia.modesetting.enable = true;
  services.xserver.videoDrivers = [ "nvidia" /*"nouveau"*/ /*"nvidiaLegacy304"*/ /*"displaylink"*/ ];
  #nixpkgs.config.xorg.abiCompat = "1.18";

  # https://nixos.org/nixos/manual/index.html#sec-container-networking
  networking.nat.enable = true;
  networking.nat.internalInterfaces = ["ve-+"];
  networking.nat.externalInterface = "bond0";

  # https://wiki.archlinux.org/index.php/Improving_performance#Input/output_schedulers
  #services.udev.extraRules = with pkgs; ''
  #  # set scheduler for ZFS member
  #  # udevadm info --query=all --name=/dev/sda
  #  ACTION=="add[change", KERNEL=="sd[a-z]", ATTR{ID_FS_TYPE}=="zfs_member", ATTR{queue/scheduler}="none"

  #  # set scheduler for NVMe
  #  ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
  #  # set scheduler for SSD and eMMC
  #  ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
  #  # set scheduler for rotating disks
  #  #ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="kyber"
  #'';

  services.sanoid = {
    enable = true;
    interval = "*:00,15,30,45"; #every 15minutes
    templates.prod = {
      frequently = 8;
      hourly = 24;
      daily = 7;
      monthly = 3;
      yearly = 0;

      autosnap = true;
    };
    templates.media = {
      hourly = 4;
      daily = 2;
      monthly = 2;
      yearly = 0;

      autosnap = true;
    };
    datasets."icybox1/safe".useTemplate = [ "prod" ];
    datasets."icybox1/safe".recursive = true;
    datasets."icybox1/safe/home/dguibert/Videos".useTemplate = [ "media" ];
    datasets."icybox1/safe/home/dguibert/Videos".recursive = true;

    templates.backup = {
      autoprune = true;
      ### don't take new snapshots - snapshots on backup
      ### datasets are replicated in from source, not
      ### generated locally
      autosnap = false;

      frequently = 0;
      hourly = 36;
      daily = 30;
      monthly = 12;
    };
    #datasets."st4000dm004-1/backup/icybox1".useTemplate = [ "prod" ];
    #datasets."st4000dm004-1/backup/icybox1".recursive = true;

    extraArgs = [ "--verbose" ];
  };

  #services.syncoid = {
  #  enable = true;
  #  #sshKey = "/root/.ssh/id_ecdsa";
  #  commonArgs = [ "--no-sync-snap" "--create-bookmark" ];
  #  #commands."pool/test".target = "root@target:pool/test";
  #  commands."icybox1/home".target = "st4000dm004-1/backup/icybox1/home";
  #  commands."icybox1/home".recursive = true;
  #};

}
