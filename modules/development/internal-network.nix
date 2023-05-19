# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{...}: {
  # Configurations of internal network for debugging purposes.

  # This enables networking for host so that it can ssh to other VMs.
  # networking.interfaces.virbr0.useDHCP = false;
  # systemd.network.networks."virbr0".dhcpV4Config.ClientIdentifier = "mac";
}
