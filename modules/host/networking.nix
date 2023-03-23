# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{...}: {
  networking = {
    enableIPv6 = false;
    firewall.allowedUDPPorts = [67]; # DHCP
    useNetworkd = true;
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "virbr1" ];
  };

  systemd.network = {
    netdevs."virbr0".netdevConfig = {
      Kind = "bridge";
      Name = "virbr0";
    };
    netdevs."virbr1".netdevConfig = {
      Kind = "bridge";
      Name = "virbr1";
    };
    networks."virbr0" = {
      matchConfig.Name = "virbr0";
      networkConfig.DHCPServer = false;
    #  addresses = [
    #    {
    #      addressConfig.Address = "192.168.100.1/24";
    #    }
    #  ];
    };
    networks."virbr1" = {
      matchConfig.Name = "virbr1";
      networkConfig.DHCPServer = false;
      /*
      # This is here if dhcp is needed
      networkConfig.DHCPServer = true;
      addresses = [
        {
          addressConfig.Address = "192.168.101.1/24";
        }
      ];
      dhcpServerStaticLeases = [
        {
         dhcpServerStaticLeaseConfig = {
            Address = "192.168.101.2";
            MACAddress = "02:00:00:01:01:02";
          };
        }
        {
         dhcpServerStaticLeaseConfig = {
            Address = "192.168.101.3";
            MACAddress = "02:00:00:01:01:03";
          };
        }
      ];
      */
    };
    # Connect VM tun/tap devices to bridges
    networks."11-netvm" = {
      matchConfig.Name = "vmbr0-*";
      networkConfig.Bridge = "virbr0";
    };
    networks."11-proxyvm" = {
      matchConfig.Name = "vmbr1-*";
      networkConfig.Bridge = "virbr1";
    };
  };
}
