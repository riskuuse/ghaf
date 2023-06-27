# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  microvm,
  system,
}:
lib.nixosSystem {
  inherit system;
  modules = [
    # TODO: Enable only for development builds
    ../../modules/users/accounts.nix
    {
      ghaf.users.accounts.enable = true;
    }
    ../../modules/development/ssh.nix
    {
      ghaf.development.ssh.daemon.enable = true;
    }
    ../../modules/development/debug-tools.nix
    {
      ghaf.development.debug.tools.enable = true;
    }

    microvm.nixosModules.microvm

    ({
      pkgs,
      lib,
      ...
    }: {
      networking.hostName = "example-appvm";
      system.stateVersion = lib.trivial.release;

      microvm.hypervisor = "qemu";

      networking = {
        enableIPv6 = false;
        # interfaces.eth0.useDHCP = true;
        firewall.allowedTCPPorts = [22]; # SSH
        # firewall.allowedUDPPorts =  [];
        useNetworkd = true;
      };

      systemd.network.enable = true;

      systemd.network.links."10-eth0" = {
        matchConfig.PermanentMACAddress = "02:00:00:02:03:04";
        linkConfig.Name = "eth0";
      };

      systemd.network.networks = {
        "10-eth0" = {
          matchConfig.PermanentMACAddress = "02:00:00:02:03:04";
          DHCP = "ipv4";
          dhcpV4Config.ClientIdentifier = "mac";
          # Set IP-address for debugging subnet
          addresses = [
            {
              addressConfig.Address = "192.168.111.3/24";
            }
          ];
          linkConfig.ActivationPolicy = "always-up";
        };
      };

      microvm.interfaces = [
        {
          type = "tap";
          id = "vmbr1-appvm";
          mac = "02:00:00:02:03:04";
        }
      ];

      environment.systemPackages = with pkgs; [
        elinks
      ];

      microvm.qemu.bios.enable = false;
    })
  ];
}
