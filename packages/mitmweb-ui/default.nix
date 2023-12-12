# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenvNoCC,
  pkgs,
  lib,
  ...
}: let
  waypipePort = 1100; # TODO: remove hardcoded port number
  nmLauncher =
    pkgs.writeShellScript
    "mitmweb-ui"
    ''
      # Create ssh-tunnel between chromium-vm and ids-vm
      ${pkgs.openssh}/bin/ssh -i /run/waypipe-ssh/id_ed25519 \
          -o StrictHostKeyChecking=no \
          -t ghaf@chromium-vm.ghaf \
              ${pkgs.openssh}/bin/ssh -M -S /tmp/control_socket \
              -f -N -L 8081:localhost:8081 ghaf@192.168.100.3
      # TODO: check pipe creation failures

      # Launch chromium application and open mitmweb page
      ${pkgs.openssh}/bin/ssh -i /run/waypipe-ssh/id_ed25519 -o StrictHostKeyChecking=no chromium-vm.ghaf \
          ${pkgs.waypipe}/bin/waypipe --border=#ff5733,5 --vsock -s ${toString waypipePort} server \
          chromium --enable-features=UseOzonePlatform --ozone-platform=wayland \
          http://localhost:8081

      # Use the control socket to close the ssh tunnel between chromium-vm and ids-vm
      ${pkgs.openssh}/bin/ssh -i /run/waypipe-ssh/id_ed25519 \
          -o StrictHostKeyChecking=no \
          -t ghaf@chromium-vm.ghaf \
              ${pkgs.openssh}/bin/ssh -q -S /tmp/control_socket -O exit ghaf@192.168.100.3
    '';
in
  stdenvNoCC.mkDerivation {
    name = "mitmweb-ui";

    phases = ["installPhase"];

    installPhase = ''
      mkdir -p $out/bin
      cp ${nmLauncher} $out/bin/mitmweb-ui
    '';

    meta = with lib; {
      description = "Script to launch Chromium to open mitmweb interface using ssh-tunneling and authentication.";
      platforms = [
        "x86_64-linux"
      ];
    };
  }
