# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  self,
  netvm,
  proxyvm,
}: {config, ...}: {
  microvm.host.enable = true;

  microvm.vms."${netvm}" = {
    flake = self;
    autostart = true;
  };

  microvm.vms."${proxyvm}" = {
    flake = self;
    autostart = true;
  };
}
