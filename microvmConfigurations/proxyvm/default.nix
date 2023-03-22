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

      networking.enableIPv6 = false;
      networking.interfaces.eth0.useDHCP = true;
      networking.interfaces.eth1.useDHCP = true;
      networking.firewall.allowedTCPPorts = [ 22 80 443 8080 ];
      networking.defaultGateway = {
        address = "192.168.100.1";
        # interface = "eth1";
      };
      networking.nat = {
        enable = true;
        internalInterfaces = [ "eth0" ];
        externalInterface = "eth1";
        # extraCommands = "iptables -t nat -A POSTROUTING -d 10.100.0.3 -p tcp -m tcp --dport 80 -j MASQUERADE";
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
