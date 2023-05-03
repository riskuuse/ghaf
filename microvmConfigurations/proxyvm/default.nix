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
      networking.hostName = "proxyvm";
      # TODO: Maybe inherit state version
      system.stateVersion = "22.11";

      microvm.hypervisor = "qemu";

      networking = {
        enableIPv6 = false;
        # useDHCP = false;
        interfaces.eth0.useDHCP = false;
        interfaces.eth1.useDHCP = true;
        useNetworkd = true;

        /*
        interfaces.eth0 = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = "192.168.101.2/32";
              prefixLength = 24;
            }
          ];
        };
        interfaces.eth1 = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = "192.168.100.2/32";
              prefixLength = 24;
            }
          ];
        };
        */
        firewall.allowedTCPPorts = [ 22 80 443 8080 ];
        firewall.allowedUDPPorts = [ 67 ];
        /*
        defaultGateway = {
          address = "192.168.100.1";
          interface = "eth1";
          metric = 10;
        };
        */
        nat = {
          enable = true;
          internalInterfaces = [ "eth0" ];
          externalInterface = "eth1";
          extraCommands = ''
	    iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080
	    iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 8080
	  '';
        };  
      };
      systemd.network = {
        networks."40-eth0" = {
          matchConfig.Name = "eth0";
          networkConfig.DHCPServer = true;
          addresses = [
            {
              addressConfig.Address = "192.168.101.2/24";
            }
          ];
          dhcpServerStaticLeases = [
            {
              dhcpServerStaticLeaseConfig = {
                Address = "192.168.101.3";
                MACAddress = "02:00:00:01:01:03";
              };
            }
          ];
        };
	# This is required if networkd is in use,
	# since in that case DUID is used as identifier by default
        networks."40-eth1".dhcpV4Config.ClientIdentifier = "mac";
      };
      microvm.interfaces = [
        {
          type = "tap";
          id = "vmbr0-proxy";
          mac = "02:00:00:01:00:02";
        }
        {
          type = "tap";
          id = "vmbr1-proxy";
          mac = "02:00:00:01:01:02";
        }
      ];
      environment.systemPackages = [
        pkgs.tcpdump
        pkgs.traceroute
        pkgs.mitmproxy
      ];
    })
  ];
}
