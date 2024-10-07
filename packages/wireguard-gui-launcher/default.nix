# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  writeShellApplication,
  #writeShellScriptBin,
  polkit,
  wireguard-gui,
  lib,
  ...
}:
/*
writeShellScriptBin "wireguard-gui-launcher" ''
  PATH=/run/wrappers/bin:/home/ghaf/.nix-profile/bin:/nix/profile/bin:/home/ghaf/.local/state/nix/profile/bin:/etc/profiles/per-user/ghaf/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin
  _=/run/current-system/sw/bin/env
  /run/current-system/sw/bin/wireguard-gui
''
*/
writeShellApplication {
  name = "wireguard-gui-launcher";
  runtimeInputs = [
    polkit
    wireguard-gui
  ];
  text = ''
    PATH=/run/wrappers/bin:/run/current-system/sw/bin
    ${wireguard-gui}/bin/wireguard-gui
  '';

  meta = {
    description = "Script to run wireguard-gui";
    platforms = lib.platforms.linux;
  };
}
