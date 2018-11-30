{
  network.description = "NixOS Network";
  network.enableRollback = true;

  defaults = { nodes, pkgs, config, lib, ...}: {
    imports = [
      <home-manager/nixos>
    ];

    environment.systemPackages = [ pkgs.vim ];
    # Select internationalisation properties.
    i18n = {
       consoleFont = "Lat2-Terminus16";
       consoleKeyMap = "fr";
       defaultLocale = "en_US.UTF-8";
     };
  
    # Set your time zone.
    time.timeZone = "Europe/Paris";

    users.mutableUsers = false;

    # Enable ZeroTierOne
    services.zerotierone.enable = true;
    services.zerotierone.joinNetworks = [ "e5cd7a9e1cd44c48" ];

    networking.useNetworkd = true;
    networking.dnsExtensionMechanism=false; #disable the edns0 option in resolv.conf. (most popular user of that feature is DNSSEC)
    services.nscd.enable = false; # no real gain (?) on workstations
    # unreachable DNS entries from home
    networking.hosts = {
      "208.118.235.200" = [ "ftpmirror.gnu.org" ];
      "208.118.235.201" = [ "git.savannah.gnu.org" ];
    };

    # disnix target
    services.disnix.enable = true;
    dysnomia.properties.mem = "$(grep 'MemTotal:' /proc/meminfo | sed -e 's/kB//' -e 's/MemTotal://' -e 's/ //g')";
    dysnomia.properties.disks = "$(ls /dev/disk/by-id/ | grep -v -- '-part.*' | tr '\\\\n' ' ')";
    # https://hydra.nixos.org/job/disnix/disnix-trunk/tarball/latest/download-by-type/doc/manual/#chap-packages
    environment.variables.PATH = [ "/nix/var/nix/profiles/disnix/default/bin" ];

    # Package ‘openafs-1.6.22.2-4.18.4’ in /home/dguibert/code/nixpkgs/pkgs/servers/openafs/1.6/module.nix:49 is marked as broken, refusing to evaluate.
    nixpkgs.config.allowBroken = true;
  };

  orsine = { pkgs, config, lib, ...}: {
    imports = [
      <modules/yubikey-gpg.nix>
      <modules/distributed-build.nix>
      <modules/nix-conf.nix>
      <modules/x11.nix>
    ];
    #deployment.targetHost = "10.147.17.123";
    environment.systemPackages = [ pkgs.disnixos pkgs.wireguard-tools ];

    #deployment.keys.wireguard_key.text = pass_ "wireguard/orsine";
    #deployment.keys.wireguard_key.destDir = "/secrets";

    # for X1.nix
    services.xserver.resolutions = [{x=1440; y=900;}];
    services.xserver.videoDrivers = [ "intel" ];
    hardware.opengl.extraPackages = [ pkgs.vaapiIntel ];
    #################################################################
    # Test raw networkd wireguard support
    # boot.extraModulePackages = [ pkgs.linuxPackages.wireguard ];
    #environment.systemPackages = [ pkgs.wireguard-tools ];
    #deployment.keys."41-wg1-k.netdev".text = if builtins.extraBuiltins ? pass then builtins.extraBuiltins.pass "wireguard/orsine-netdev" else "";
    #deployment.keys."41-wg1-k.netdev".destDir = "/etc/systemd/network/";

    ## after 40-*, before 99-main
    #systemd.network.netdevs."41-wg1" = {
    #  netdevConfig.Name = "wg1";
    #  netdevConfig.Kind = "wireguard";

    #  wireguardConfig.PrivateKey = "ADGL+IMKmoAcBl8vRy1re0JuYSiKZWueQAhzEw3ijXw=";
    #  wireguardPeers = [
    #    { wireguardPeerConfig = {
    #          AllowedIPs = [ "10.147.27.0/24" "fe80::/64" ];
    #          PublicKey  = "wBBjx9LCPf4CQ07FKf6oR8S1+BoIBimu1amKbS8LWWo=";
    #          Endpoint   = "83.155.85.77:500";
    #    }; }
    #  ];
    #};
    #systemd.network.networks."41-wg1" = {
    #  networkConfig.Description="my Home VPN based on WireGuard";
    #  matchConfig.Name="wg1";
    #  address = [ "10.147.27.123/24" ];
    #};
    #[Service]
    #Type=oneshot
    #ExecStart=/bin/bash -c "/bin/echo 'br0 available, setting MAC ' `/bin/cat /sys/class/net/wlan0/address`"
    #ExecStart=/bin/bash -c "/sbin/ip link set br0 address `/bin/cat /sys/class/net/wlan0/address`"
    #
    #[Install]
    #WantedBy=sys-subsystem-net-devices-br0.device
    # sys-subsystem-net-devices-wg1.device
    #################################################################
    #################################################################
    ### mesh wg0
    #services.babeld.enable = true;
    #services.babeld.interfaces.wg0 = {
    #  type = "tunnel";
    #};
    #systemd.network.networks."41-wg0".address = [ "fe80::cafe:1" ];
    # ip -6 addr add $(ahcp-generate-address fe80::) dev wg1
    #services.babeld.extraConfig = ''
    #redistribute local if <interface> deny
    #'';
  };

  rpi31 = { pkgs, config, lib, ...}: {
    #toString <secrets/wpa_supplicant.conf>;
    environment.noXlibs = true;
    #home-manager.users.dguibert = import ~/.config/nixpkgs/home-nox11.nix { inherit pkgs lib; };
    users.users.rdolbeau = {
      isNormalUser = true;
      uid = 1501;
      group = "rdolbeau";
      openssh.authorizedKeys.keys = [
	"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZMjCvizoNrDojOFOMazBBgFfyFrBieu5DFiiFgY4VJHPtOchSPAF4K+Q8hgbFU1cP8q4NoncPSS2BEp3FAtiuUZyHRV72yUlx12BOdlVpAtpjtphr2CZMPhzo89k1yQ6W2sHP52igF9DWeMTj9lLgpjjsCbA8qjT3cdLUiDh0anrFQjzgGRemhuxxsUV8L0XB4TDfg0/qSOrrKNLX5NnuEghpJOak3NS/2WDz6QGQbqdUKlKxDcHuaLK1FJRSvJIUFk23EUv8TfwL3B8u9FMblFFM5BUHelNpNNobI7LfTJB/Qv2YVEWjFXirSJEf7U0MCeLDu9hrKPGu1X8kmWc7 dolbeau@c2sbe"
        "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCT6I73vMHeTX7X990bcK+RKC8aqFYOLZz5uZhwy8jtx/xEEbKJFT/hggKADaBDNkJl/5141VUJ+HmMEUMu+OznK2gE8IfTNOP1zLXD6SjOxCa55MvnyIiXVMAr7R0uxZWy28IrmcmSx1LY5Mx8V13mjY3mp3LVemAy9im+vj6FymjQqgPMg6dHq+aQCeHpx22GWHYEq2ghqEsRpmIBBwwaVaEH8YIjcqZwDcp273SzBrgMEW44ndul5bvh85c71vjm7kblU/BxwBeLFMJFnXYTPxF2JjxhCSMlHBH9hqQjQ8vwaQev6XaJ5TpHgiT3nLAxCyBBgvnfwM7oq6bjHjuyToKFzUsFH6YVsK+/NjagZ5YKlV7vK0o2oF12GrQvwWwa6DUM+LdUNmSX4l4Xq8lB5YbJ5NK0pHRRdzCZL5kPuV+CkXRAHoUSj/pLUqkqGRL70NMtLIYmQbj/l7BZ4PQNP9zKLB4f5pk02A25DbPVfoW2DFL0DRfSF1L8ZDsAVhzUaRKSBZZ4wG231gvB6pCMTpeuvC9+Z/OmYkiXEOn34Qdjx8Bfi7XWKm/PnSgP7dM9Tcf3I0hvymvP6eZ8BjeriKHUE7b3s1aMQz9I4ctpbCNT5S16XMQZtdO0HZ+nn4Exhy0FHmdCwPXu/VBEBYcy7UpI4vyb1xiz13KVX/5/oQ== CA key for my accounts at home"
      ];
    };
    users.groups.rdolbeau.gid = 1501;

  };

  vbox-57nvj72 = { pkgs, config, lib, ...}: {
    imports = [ ./vbox-57nvj72/configuration.nix
      ./nixos/yubikey-gpg.nix
      ./nixos/distributed-build.nix
      ./nixos/nix-conf.nix
    ];
    #deployment.targetHost = "10.0.2.15";
    deployment.targetHost = "10.147.17.198";
    #deployment.keys.wireguard_key.text = pass_ "wireguard/vbox-57nvj72";
    #deployment.keys.wireguard_key.destDir = "/secrets";
    ### mesh wg0
    #services.babeld.enable = true;
    #services.babeld.interfaces.wg0 = {
    #  type = "tunnel";
    #};
    #systemd.network.networks."41-wg0".address = [ "fe80::cafe:3" ];
    home-manager.users.dguibert = import ~/.config/nixpkgs/home.nix { inherit pkgs lib; };
  };

  titan = { pkgs, config, lib, ...}: {
    imports = [ ./titan/configuration.nix 
      ./nixos/yubikey-gpg.nix
      ./nixos/distributed-build.nix
      ./nixos/nix-conf.nix
      ./nixos/x11.nix
      ./nixos/zfs.nix
    ];
    deployment.targetHost = "192.168.1.24";
    #deployment.keys.wireguard_key.text = pass_ "wireguard/titan";
    #deployment.keys.wireguard_key.destDir = "/secrets";

    # services.xserver.videoDrivers = [ "nvidia" ];
    #services.xserver.videoDrivers = [ "nvidiaLegacy340" ];
    ## [   13.576513] NVRM: The NVIDIA Quadro FX 550 GPU installed in this system is
    ##                NVRM:  supported through the NVIDIA 304.xx Legacy drivers. Please
    ##                NVRM:  visit http://www.nvidia.com/object/unix.html for more
    ##                NVRM:  information.  The 340.104 NVIDIA driver will ignore
    ##                NVRM:  this GPU.  Continuing probe...
    hardware.nvidia.modesetting.enable = true;
    services.xserver.videoDrivers = [ "nvidiaLegacy304" ];

    hardware.opengl.extraPackages = [ pkgs.vaapiVdpau ];
    home-manager.users.dguibert = import ~/.config/nixpkgs/home.nix { inherit pkgs lib; };

    # https://nixos.org/nixops/manual/#idm140737318329504
    virtualisation.libvirtd.enable = true;
    virtualisation.docker.enable = true;
    networking.firewall.checkReversePath = false;
    systemd.tmpfiles.rules = [ "d /var/lib/libvirt/images 1770 root libvirtd -" ];
  };
}
