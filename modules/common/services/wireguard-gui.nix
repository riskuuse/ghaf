# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ config, lib, pkgs,... }:
let
  cfg = config.ghaf.services.wireguard-gui;
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    optionalAttrs
    hasAttr
    ;
in
{
  options.ghaf.services.wireguard-gui = {
    enable = mkEnableOption "WireGuard VPN configuration tool for app-vms";
    name = mkOption {
      type = types.str;
      description = "App-vm name for storage-vm";
    };
  };
  config = mkIf cfg.enable {
   
    environment.systemPackages = [ pkgs.wireguard-gui-launcher pkgs.polkit pkgs.wireguard-tools ];
    security.polkit = {
      enable = true;
      debug = true;
      extraConfig = ''
      polkit.addRule(function(action, subject) {
        polkit.log("user " +  subject.user + " is attempting action " + action.id + " from PID " + subject.pid);
        polkit.log("subject = " + subject);
        polkit.log("action = " + action);
        polkit.log("actioncmdline = " + action.lookup("command_line"));
      });
      polkit.addRule(function(action, subject) {
        var expectedcmdline = "XDG_RUNTIME_DIR=/run/user/1000 " +
                            "XDG_DATA_DIRS=" +
                            "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:" +
                            "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:" +
                            "${pkgs.gtk4}/share/gsettings-schemas/${pkgs.gtk4.name}:" +
                            "/home/ghaf/.nix-profile/share:" +
                            "/nix/profile/share:" +
                            "/home/ghaf/.local/state/nix/profile/share:" +
                            "/etc/profiles/per-user/ghaf/share:" +
                            "/nix/var/nix/profiles/default/share:" +
                            "/run/current-system/sw/share " +
                            "PATH=/run/wrappers/bin:/run/current-system/sw/bin " +
                            "LIBGL_ALWAYS_SOFTWARE=true " +
                            "${pkgs.wireguard-gui}/bin/.wireguard-gui-wrapped";
        polkit.log("Expected commandline = " + expectedcmdline);
        if (action.id == "org.freedesktop.policykit.exec" &&
          RegExp('^/run/current-system/sw/bin/env WAYLAND_DISPLAY=wayland-([a-zA-Z0-9]){8} $').test(action.lookup("command_line").slice(0,64)) === true &&
          action.lookup("command_line").slice(64) == expectedcmdline &&
          subject.user == "ghaf") {
        return polkit.Result.YES;
        }
      });
      '';
    };

    ghaf = optionalAttrs (hasAttr "storagevm" config.ghaf) {
      storagevm = {
        enable = true;
        inherit (cfg) name;
        directories = [
          {
            directory = "/etc/wireguard/";
            mode = "u=rwx,g=,o=";
          }
        ];
        files = [ "/etc/wireguard/wg0.conf" ];
      };
    };

    systemd.services."wireguard-template-conf" =
      let
        confScript = pkgs.writeShellScriptBin "wireguard-template-conf" ''
          set -xeuo pipefail
          wgDir="/etc/wireguard/"
          confFile="$wgDir""wg0.conf"

          if [[ -d "$wgDir" ]]; then
          echo "$wgDir already exists."
          else
          mkdir -p "$wgDir"
          fi
          if [[ -e "$confFile" ]]; then
          echo "$confFile already exists."
          else
          cat > "$confFile" <<EOF
          [Interface]
          Address = 10.10.10.5/24
          ListenPort = 51820
          PrivateKey = WIREGUARD_PRIVATE_KEY
          [Peer]
          # Name = Server
          PublicKey = PEER_PUBLIC_KEY
          AllowedIPs = 10.10.10.0
          Endpoint = PEER_IP:PORT
          EOF
          fi
          chmod 0600 "$confFile"
        '';
      in
      {
        enable = true;
        description = "Generate template WireGuard config file";
        path = [ confScript ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StandardOutput = "journal";
          StandardError = "journal";
          ExecStart = "${confScript}/bin/wireguard-template-conf";
        };
      };
  };
}