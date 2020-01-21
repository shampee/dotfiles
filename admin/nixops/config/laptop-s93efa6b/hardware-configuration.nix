# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
#  imports =
#    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
#    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" "acpi_call" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
  networking.hostId="8425e349"; # - ZFS requires networking.hostId to be set
  boot.kernelParams = ["resume=/dev/zd0" "acpi_backlight=vendor" ];
  swapDevices = [ { device = "/dev/zd0"; } ];

  fileSystems."/" =
    { device = "rt580/nixos";
      fsType = "zfs";
    };

  #fileSystems."/boot" =
  #  { device = "bt580/nixos";
  #    fsType = "zfs";
  #  };

  fileSystems."/boot".device = "/dev/nvme0n1p1";

  fileSystems."/home" =
    { device = "rt580/home";
      fsType = "zfs";
    };

  fileSystems."/root" =
    { device = "rt580/home/root";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "rt580/tmp";
      fsType = "zfs";
    };

  nix.maxJobs = lib.mkDefault 8;

  services.xserver.libinput.enable = lib.mkDefault true;
  hardware.trackpoint.enable = lib.mkDefault true;
  hardware.trackpoint.emulateWheel = lib.mkDefault config.hardware.trackpoint.enable;

  # Disable governor set in hardware-configuration.nix,
  # required when services.tlp.enable is true:
  powerManagement.cpuFreqGovernor =
    lib.mkIf config.services.tlp.enable (lib.mkForce null);

  services.tlp.enable = lib.mkDefault true;
}
