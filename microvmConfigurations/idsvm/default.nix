# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache 2.0
{
  nixpkgs,
  microvm,
  system,
}:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    # TODO: Enable only for development builds
    ../../modules/development/authentication.nix
    ../../modules/development/ssh.nix
    ../../modules/development/packages.nix

    microvm.nixosModules.microvm

    ({pkgs, ...}: {
      networking.hostName = "idsvm";
      # TODO: Maybe inherit state version
      system.stateVersion = "22.11";

      microvm.hypervisor = "qemu";

      networking = {
        enableIPv6 = false;
        interfaces.ethint0.useDHCP = false;
        interfaces.ethint1.useDHCP = false;
        useNetworkd = true;

        firewall.allowedTCPPorts = [ 22 80 443 8080 ]; # SSH, HTTP, HTTPS, MiTM-proxy
        firewall.allowedUDPPorts = [67];  # DHCP

        nat = {
          enable = true;
          internalInterfaces = [ "ethint1" ];
          externalInterface = "ethint0";
          extraCommands = ''
            iptables -t nat -A PREROUTING -i ethint1 -p tcp --dport 80 -j REDIRECT --to-port 8080
            iptables -t nat -A PREROUTING -i ethint1 -p tcp --dport 443 -j REDIRECT --to-port 8080
          '';
        };  
      };

      systemd.network.links."10-ethint0" = {
        matchConfig.PermanentMACAddress = "02:00:00:01:01:02";
        linkConfig.Name = "ethint0";
      };

      systemd.network.links."10-ethint1" = {
        matchConfig.PermanentMACAddress = "02:00:00:01:02:02";
        linkConfig.Name = "ethint1";
      };

      systemd.network.enable = true;

      systemd.network.networks = {
        "10-ethint0" = {
          gateway = ["192.168.100.1"];
          matchConfig.MACAddress = "02:00:00:01:01:02";
          networkConfig.DHCPServer = false;
          addresses = [
            {
              addressConfig.Address = "192.168.100.2/24";
            }
            {
              # IP-address for debugging subnet
              addressConfig.Address = "192.168.110.3/24";
            }
          ];
          linkConfig.ActivationPolicy = "always-up";
        };
        "10-ethint1" = {
          matchConfig.MACAddress = "02:00:00:01:02:02";
          networkConfig.DHCPServer = true;
          dhcpServerConfig.ServerAddress = "192.168.101.1/24";
          addresses = [
            {
              addressConfig.Address = "192.168.101.1/24";
            }
            {
              # IP-address for debugging subnet
              addressConfig.Address = "192.168.111.1/24";
            }
          ];
          linkConfig.ActivationPolicy = "always-up";
        };
      };

      microvm.interfaces = [
        {
          type = "tap";
          id = "vmbr0-idsvm";
          mac = "02:00:00:01:01:02";
        }
        {
          type = "tap";
          id = "vmbr1-idsvm";
          mac = "02:00:00:01:02:02";
        }
      ];
      environment.systemPackages = [
        pkgs.tcpdump
        pkgs.traceroute
        pkgs.mitmproxy
      ];

      microvm.qemu.bios.enable = false;
    })
  ];
}