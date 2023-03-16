# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  self,
  microvm,
  netvm,
  proxyvm,
  lynxvm,
}: {modulesPath, config, pkgs, ...}: {
  imports = [
    (modulesPath + "/profiles/minimal.nix")

    microvm.nixosModules.host

    (import ./microvm.nix {inherit self netvm proxyvm lynxvm;})
    ./networking.nix
  ];

  networking.hostName = "ghaf-host";
  system.stateVersion = "22.11";

  security.pam.loginLimits = [
    { domain = "ghaf"; item = "memlock"; type = "-"; value = "unlimited"; }
  ];

  systemd.services."microvm@".serviceConfig.LimitMEMLOCK = 999999999;

}
