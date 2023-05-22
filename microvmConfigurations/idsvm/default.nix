# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache 2.0
# This is a skeleton of generic network security virtual machine.
# In the first phase it implements interactive proxy (mitmproxy)
# for http(s) traffic, but this could be the place to implement:
# - Intrusion Detection Systems
# - Firewall policies
# - Deep Packet Inspections
# - VPN
# - etc
#
# TODO:
# - Add default key and certificate for mitmproxy
# - Autolaunch mitmproxy
# - Some kind of simple console connection to mitmproxy
#
# Instructions in short:
# 1. ssh to idsvm:
#    - from host: ssh ghaf@192.168.111.1
#       or
#    - from netvm: ssh ghaf@192.168.100.2
# 2. Run: mitmproxy --mode transparent
# 3. Enjoy (well, you'll need a browser to see something happening).
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

        firewall.allowedTCPPorts = [22 80 443 8080]; # SSH, HTTP, HTTPS, MiTM-proxy
        firewall.allowedUDPPorts = [67]; # DHCP

        nat = {
          enable = true;
          internalInterfaces = ["ethint1"];
          externalInterface = "ethint0";
          # Firewall rules to redirect http(s) to mitmproxy.
          # If mitmproxy is not running, this will block
          # http(s) to other VMs.
          extraCommands = ''
            iptables -t nat -A PREROUTING -i ethint1 -p tcp --dport 80 -j REDIRECT --to-port 8080
            iptables -t nat -A PREROUTING -i ethint1 -p tcp --dport 443 -j REDIRECT --to-port 8080
          '';
        };
      };

      # There are two network interfaces. The ethint0 handles connections outside i.e.
      # towards NetVM and the ethint1 will be used to share the network to other guest VMs.
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
