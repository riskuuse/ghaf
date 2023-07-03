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

      ({lib, pkgs, ...}: {
        networking.hostName = "example-appvm";
        system.stateVersion = lib.trivial.release;

        microvm.hypervisor = "qemu";

        networking = {
          enableIPv6 = false;
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

            # This is needed if networkd is used and it is necessary to have MAC
            # as an identifier for DHCP leases. Otherwise DUID is used by default.
            dhcpV4Config.ClientIdentifier = "mac";

            # Set IP-address for debugging subnet.
            # This static address can be used to have straight ssh connection
            # from host to this particular appvm for debugging purposes.
            # Address 192.168.111.1 is reserved for idsvm and
            # address 192.168.111.2 is reserved for the host.
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
            # The interface ID must have prefix "vmbr1-".
            # This is a way host connects right tap devices
            # to virtual bridge virbr1.
            id = "vmbr1-appvm";
            mac = "02:00:00:02:03:04";
          }
        ];

        environment.systemPackages = with pkgs; [
          elinks
          lynx
        ];

        # Here we add CA certificate of the mitmproxy to the file of trusted certificates
        # at /etc/ssl/certs/ca-certificates.crt as well as to the ca-bundle.crt.
        # However many of applications that use TLS protocol does not make use of system
        # level trusted CA certificates. For example many browsers have their own CA
        # certificate storage and adding custom certificates there may be complicated.
        security.pki.certificateFiles = [./mitmproxy-ca/mitmproxy-ca-cert.cer];

        # This is an optional method to just add the CA certificate file to
        # /etc/mitmproxy/ directory. Applications do not find it automatically from there,
        # but may be configured to use it.
        environment.etc = {
          "mitmproxy/mitmproxy-ca-cert.pem".source = ./mitmproxy-ca/mitmproxy-ca-cert.pem;
        };

        microvm.qemu.bios.enable = false;
        microvm.storeDiskType = "squashfs";
      })
    ]
    ++ (import ../../module-list.nix);
}
