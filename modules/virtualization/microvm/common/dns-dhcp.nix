# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{...}: let
  domain = "ghaf";
in {
  # Disable resolved since we are using Dnsmasq
  services.resolved.enable = false;

  # Dnsmasq is used as a DHCP/DNS server inside the NetVM
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    settings = {
      # keep local queries within domain by
      # caching them within dnsmasq. query outside
      # only if name is not available locally
      server = ["192.168.100.1" "8.8.8.8"];
      dhcp-range = ["192.168.100.2,192.168.100.254"];
      dhcp-sequential-ip = true;
      dhcp-authoritative = true;
      domain = "${domain}";
      local = "/${domain}/";
      listen-address = ["127.0.0.1,192.168.100.1"];
      dhcp-option = [
        "option:router,192.168.100.1"
        "option:dns-server,192.168.100.1"
      ];
      expand-hosts = true;
      domain-needed = true;
      bogus-priv = true;

      # static IP addresses for the guests
      dhcp-host = "02:00:00:02:02:02,192.168.100.3,gui-vm";
    };
  };
}
