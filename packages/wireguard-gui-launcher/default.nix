# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  writeShellApplication,
  coreutils,
  polkit,
  polkit_gnome,
  wireguard-gui,
  lib,
  ...
}:
writeShellApplication {
  name = "wireguard-gui-launcher";
  runtimeInputs = [
    coreutils
    polkit
  ];
  text = ''
    # ${polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
    ${polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
    ${coreutils}/bin/sleep 2
    ${wireguard-gui}/bin/wireguard-gui
    # pkill -f polkit-gnome-authentication-agent-1
  '';

  meta = {
    description = "Script to run wireguard-gui";
    platforms = lib.platforms.linux;
  };
}
