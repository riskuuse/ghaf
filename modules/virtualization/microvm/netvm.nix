# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}: let
  configHost = config;
  vmName = "net-vm";
  macAddress = "02:00:00:01:01:01";
  netvmBaseConfiguration = {
    imports = [
      (import ./common/vm-networking.nix {inherit vmName macAddress;})
      ({lib, ...}: {
        ghaf = {
          users.accounts.enable = lib.mkDefault configHost.ghaf.users.accounts.enable;
          development = {
            # NOTE: SSH port also becomes accessible on the network interface
            #       that has been passed through to NetVM
            ssh.daemon.enable = lib.mkDefault configHost.ghaf.development.ssh.daemon.enable;
            debug.tools.enable = lib.mkDefault configHost.ghaf.development.debug.tools.enable;
          };
        };

        system.stateVersion = lib.trivial.release;

        nixpkgs.buildPlatform.system = configHost.nixpkgs.buildPlatform.system;
        nixpkgs.hostPlatform.system = configHost.nixpkgs.hostPlatform.system;

        microvm.hypervisor = "qemu";

        networking = {
          firewall.allowedTCPPorts = [53];
          firewall.allowedUDPPorts = [53 51820];
        };

        # Add simple wi-fi connection helper
        environment.systemPackages = lib.mkIf config.ghaf.profiles.debug.enable [pkgs.wifi-connector pkgs.wireguard-tools];

        environment.etc."wireguard/wg0.conf" = {
          text = ''
            [Interface]
            Address = 10.10.1.1/24
            ListenPort = 51820
            PrivateKey = eDy1+e8cB20z/QNfAkKimhtHnmlL+lJLvVaZTjiO61A=

            [Peer]
            PublicKey = y5DplS7UbRbVrVJ0lrgWyelBtEKeKbc4B34Y2yZ6Uhg=
            AllowedIPs = 10.10.1.3/32
            Endpoint = 192.168.100.3:51820
          '';
          mode = "0600";
        };

        # Dnsmasq is used as a DHCP/DNS server inside the NetVM
        services.dnsmasq = {
          enable = true;
          resolveLocalQueries = true;
          settings = {
            server = ["8.8.8.8"];
            dhcp-range = ["192.168.100.2,192.168.100.254"];
            dhcp-sequential-ip = true;
            dhcp-authoritative = true;
            domain = "ghaf";
            listen-address = ["127.0.0.1,192.168.100.1"];
            dhcp-option = [
              "option:router,192.168.100.1"
              "6,192.168.100.1"
            ];
            expand-hosts = true;
            domain-needed = true;
            bogus-priv = true;
          };
        };

        # Disable resolved since we are using Dnsmasq
        services.resolved.enable = false;

        systemd.network = {
          enable = true;
          networks."10-ethint0" = {
            matchConfig.MACAddress = macAddress;
            addresses = [
              {
                addressConfig.Address = "192.168.100.1/24";
              }
              {
                # IP-address for debugging subnet
                addressConfig.Address = "192.168.101.1/24";
              }
            ];
            linkConfig.ActivationPolicy = "always-up";
          };
        };

        microvm = {
          optimize.enable = true;
          shares = [
            {
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
            }
          ];
          writableStoreOverlay = lib.mkIf config.ghaf.development.debug.tools.enable "/nix/.rw-store";
        };

        imports = import ../../module-list.nix;
      })
    ];
  };
  cfg = config.ghaf.virtualization.microvm.netvm;
in {
  options.ghaf.virtualization.microvm.netvm = {
    enable = lib.mkEnableOption "NetVM";

    extraModules = lib.mkOption {
      description = ''
        List of additional modules to be imported and evaluated as part of
        NetVM's NixOS configuration.
      '';
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    microvm.vms."${vmName}" = {
      autostart = true;
      config =
        netvmBaseConfiguration
        // {
          imports =
            netvmBaseConfiguration.imports
            ++ cfg.extraModules;
        };
      specialArgs = {inherit lib;};
    };
  };
}
