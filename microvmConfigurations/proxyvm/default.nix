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
      networking.firewall.allowedTCPPorts = [ 22 80 443 8080 ];

      microvm.interfaces = [
        {
          type = "tap";
          id = "vm-proxy";
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
