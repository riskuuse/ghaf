# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
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
      networking.hostName = "netvm";
      # TODO: Maybe inherit state version
      system.stateVersion = "22.11";

      # For WLAN firmwares
      hardware.enableRedistributableFirmware = true;

      microvm.hypervisor = "qemu";
      # microvm.hypervisor = "crosvm";
      
      networking = {
        enableIPv6 = false;
        interfaces.eth0.useDHCP = false;
        firewall = {
          allowedTCPPorts = [ 22 ];
          allowedUDPPorts = [ 67 ];
        };
        useNetworkd = true;
        usePredictableInterfaceNames = true;
        nat = {
          enable = true;
          internalInterfaces = [ "eth0" ];
          externalInterface = "wlp0s1f0";
        };
      };

      # This does not work. Currently replaced by environment.etc configuration.
      #systemd.network = {
      #  networks."eth0" = {
      #    matchConfig.Name = "eth0";
      #    networkConfig.DHCPServer = true;
      #    addresses = [
      #      {
      #        addressConfig.Address = "192.168.100.1/24";
      #      }
      #    ];
      #  };
      #};

      # TODO: Idea. Maybe use udev rules for connecting
      # USB-devices to crosvm

      # TODO: Move these to target-specific modules
      # microvm.devices = [
      #   {
      #     bus = "usb";
      #     path = "vendorid=0x050d,productid=0x2103";
      #   }
      # ];
      microvm.devices = [
        {
          bus = "pci";
          path = "0001:01:00.0";
        }
      ];

      # TODO: Move to user specified module - depending on the use x86_64
      #       laptop pci path
      # x86_64 Laptop
      # microvm.devices = [
      #   {
      #     bus = "pci";
      #     path = "0000:03:00.0";
      #   }
      #   {
      #     bus = "pci";
      #     path = "0000:05:00.0";
      #   }
      # ];
      microvm.interfaces = [
        {
          type = "tap";
          id = "vmbr0-netvm";
          mac = "02:00:00:01:01:01";
        }
      ];

      networking.wireless = {
        enable = true;
        networks."Virranniemi_Guest".psk = "Vieraat ovat idiootteja.";
      };

      environment.etc."systemd/network/40-eth0.network".text = pkgs.lib.mkForce ''
        [Match]
        Name=eth0

        [Network]
        DHCPServer=true

        [Address]
        Address=192.168.100.1/24
      '';

    })
  ];
}
