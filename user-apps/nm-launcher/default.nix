# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenvNoCC,
  pkgs,
  lib,
  stdenv,
  ...
}: let
  nmLauncher =
    pkgs.writeShellScript
    "nm-launcher"
    ''
      export DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/ssh_session_dbus.sock
      export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/tmp/ssh_system_dbus.sock
      ssh -fNq ghaf@192.168.100.1 \
          -i /etc/ssh/waypipe-ssh \
          -o StrictHostKeyChecking=no \
          -L /tmp/ssh_session_dbus.sock:/run/user/1000/bus \
          -L /tmp/ssh_system_dbus.sock:/run/dbus/system_bus_socket \
          -o StreamLocalBindUnlink=yes
      nm-connection-editor &
    '';
in
  stdenvNoCC.mkDerivation {
    name = "nm-launcher";

    phases = ["installPhase"];

    installPhase = ''
      mkdir -p $out/bin
      cp ${nmLauncher} $out/bin/nm-launcher
    '';

    meta = with lib; {
      description = "Script to launch nm-connection-editor to configure network of netvm using D-Bus over SSH.";
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
  }
