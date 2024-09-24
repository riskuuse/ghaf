# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  writeShellApplication,
  polkit,
  wireguard-gui,
  lib,
  ...
}:
writeShellApplication {
  name = "wireguard-gui-launcher";
  runtimeInputs = [
    polkit
  ];
  text = ''
    ${wireguard-gui}/bin/wireguard-gui
  '';

  meta = {
    description = "Script to run wireguard-gui";
    platforms = lib.platforms.linux;
  };
}
