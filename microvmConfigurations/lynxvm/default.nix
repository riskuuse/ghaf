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
      networking.hostName = "lynxvm";
      # TODO: Maybe inherit state version
      system.stateVersion = "22.11";

      microvm.hypervisor = "qemu";

      networking = {
        enableIPv6 = false;
        interfaces.eth0.useDHCP = true;
        /*
        interfaces.eth0 = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = "192.168.101.3/32";
              prefixLength = 24;
            }
          ];
        };
        */
        firewall.allowedTCPPorts = [ 22 80 443 8080 ];
        defaultGateway = {
          address = "192.168.101.2";
          interface = "eth0";
          metric = 10;
        };
      };
      /*
      networking.enableIPv6 = false;
      networking.interfaces.eth0.useDHCP = true;
      networking.firewall.allowedTCPPorts = [ 22 80 443 8080 ];
      networking.defaultGateway = {
        address = "192.168.101.2";
        interface = "eth0";
        metric = 0;
      };
      */
      /*
      systemd.network = {
        networks."40-eth0" = {
          matchConfig.Name = "eth0";
          networkConfig.DHCPServer = false;
          addresses = [
            {
              addressConfig.Address = "192.168.101.3/24";
            }
          ];
        };
      };
      */
      microvm.interfaces = [
        {
          type = "tap";
          id = "vmbr1-lynx";
          mac = "02:00:00:01:01:03";
        }
      ];

      environment.systemPackages = [
        pkgs.tcpdump
        pkgs.traceroute
        pkgs.lynx
      ];
    })
  ];
}
