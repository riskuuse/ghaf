# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  microvm,
  system,
}:
lib.nixosSystem {
  inherit system;
  specialArgs = {inherit lib;};
  modules =
    [
      {
        ghaf = {
          users.accounts.enable = true;
          development = {
            ssh.daemon.enable = true;
            debug.tools.enable = true;
          };
        };
      }

      microvm.nixosModules.microvm

      ({lib, ...}: {
        networking.hostName = "netvm";
        # TODO: Maybe inherit state version
        system.stateVersion = lib.trivial.release;

        # TODO: crosvm PCI passthrough does not currently work
        microvm.hypervisor = "qemu";

        networking = {
          enableIPv6 = false;
          interfaces.ethint0.useDHCP = false;
          firewall.allowedTCPPorts = [22];
          useNetworkd = true;
        };

        microvm.interfaces = [
          {
            type = "tap";
            id = "vmbr0-netvm";
            mac = "02:00:00:01:01:01";
          }
        ];

        networking.nat = {
          enable = true;
          internalInterfaces = ["ethint0"];
          internalIPs = ["192.168.100.0/24"];
        };

        # Set internal network's interface name to ethint0
        systemd.network.links."10-ethint0" = {
          matchConfig.PermanentMACAddress = "02:00:00:01:01:01";
          linkConfig.Name = "ethint0";
        };

        systemd.network = {
          enable = true;
          networks."10-ethint0" = {
            matchConfig.MACAddress = "02:00:00:01:01:01";
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

        microvm.qemu.bios.enable = false;
        microvm.storeDiskType = "squashfs";
      })
    ]
    ++ (import ../../module-list.nix);
}
