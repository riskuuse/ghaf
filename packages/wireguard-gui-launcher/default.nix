# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  writeShellApplication,
  polkit_gnome,
  wireguard-gui,
  lib,
  ...
}:
writeShellApplication {
  name = "wireguard-gui-launcher";
  text = ''
    ${polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
    sleep 2
    ${wireguard-gui}/bin/wireguard-gui
    pkill -f polkit-gnome-authentication-agent-1
  '';

  meta = {
    description = "Script to run wireguard-gui";
    platforms = lib.platforms.linux;
  };
}
