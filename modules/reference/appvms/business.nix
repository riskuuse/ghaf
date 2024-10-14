# Copyright 2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf optionalString;
  #TODO: Move this to a common place
  name = "business";
  tiiVpnAddr = "151.253.154.18";
  vpnOnlyAddr = "${tiiVpnAddr},jira.tii.ae,access.tii.ae,confluence.tii.ae,i-service.tii.ae,catalyst.atrc.ae";
  netvmEntry = builtins.filter (x: x.name == "net-vm") config.ghaf.networking.hosts.entries;
  netvmAddress = lib.head (builtins.map (x: x.ip) netvmEntry);
  adminvmEntry = builtins.filter (x: x.name == "admin-vm") config.ghaf.networking.hosts.entries;
  adminvmAddress = lib.head (builtins.map (x: x.ip) adminvmEntry);
in
{
  name = "${name}";
  packages =
    [
      pkgs.chromium
      pkgs.globalprotect-openconnect
      pkgs.losslesscut-bin
      pkgs.openconnect
      pkgs.gnome-text-editor
      pkgs.xarchiver
      pkgs.wireguard-tools
      pkgs.wireguard-gui
      pkgs.wireguard-gui-launcher
      pkgs.polkit
    ]
    ++ lib.optionals config.ghaf.profiles.debug.enable [ pkgs.tcpdump ]
    ++ lib.optionals config.ghaf.givc.enable [ pkgs.open-normal-extension ];

  # TODO create a repository of mac addresses to avoid conflicts
  macAddress = "02:00:00:03:10:01";
  ramMb = 6144;
  cores = 4;
  extraModules = [
    (
      { pkgs, ... }:
      {
        imports = [
          ../programs/chromium.nix
          ../services/globalprotect-vpn/default.nix
        ];
        time.timeZone = config.time.timeZone;

        microvm = {
          qemu.extraArgs = lib.optionals (
            config.ghaf.hardware.usb.internal.enable
            && (lib.hasAttr "cam0" config.ghaf.hardware.usb.internal.qemuExtraArgs)
          ) config.ghaf.hardware.usb.internal.qemuExtraArgs.cam0;
          devices = [ ];
        };

        ghaf.systemd.withPolkit = true;
        security.polkit = {
          enable = true;
          debug = true;
          /*
          extraConfig = ''
            polkit.addRule(function(action, subject) {
              polkit.log("user " +  subject.user + " is attempting action " + action.id + " from PID " + subject.pid);
              polkit.log("subject = " + subject);
              polkit.log("action = " + action);
              polkit.log("actioncmdline = " + action.lookup("command_line"));
            });
            polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.policykit.exec" &&
                # RegExp('^ $')
                # action.lookup("command_line") == "/run/current-system/sw/bin/env WAYLAND_DISPLAY=wayland- \
                # XDG_RUNTIME_DIR=/run/user/1000 \
                # XDG_DATA_DIRS=/nix/store/b4mxjw5xdpg4xdc5mpcc0aslv020fdil-wireguard-gui-0.1.0/share:/nix/store/q9j6abi6igq18j6r83816ijh7iml18n6-gsettings-desktop-schemas-46.0/share/gsettings-schemas/gsettings-desktop-schemas-46.0:/nix/store/b0mia9q9d2cg6zkyhv7ra66nhcchsrws-gtk+3-3.24.43/share/gsettings-schemas/gtk+3-3.24.43:/nix/store/d6mpknk4fx2zcll7h0z31nhwbm0zcgc7-gtk4-4.14.4/share/gsettings-schemas/gtk4-4.14.4:/home/ghaf/.nix-profile/share:/nix/profile/share:/home/ghaf/.local/state/nix/profile/share:/etc/profiles/per-user/ghaf/share:/nix/var/nix/profiles/default/share:/run/current-system/sw/share \
                # PATH=/run/wrappers/bin:/run/current-system/sw/bin \
                # LIBGL_ALWAYS_SOFTWARE=true \
                # /nix/store/b4mxjw5xdpg4xdc5mpcc0aslv020fdil-wireguard-gui-0.1.0/bin/.wireguard-gui-wrapped" &&
                subject.user == "ghaf") {
              return polkit.Result.YES;
              }
            });
          '';
          */
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
                                    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/gsettings-desktop-schemas-46.0:" +
                                    "${pkgs.gtk3}/share/gsettings-schemas/gtk+3-3.24.43:" +
                                    "${pkgs.gtk4}/share/gsettings-schemas/gtk4-4.14.5:" +
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
        /*
        environment.etc."wireguard/wg0.conf" = {
            text = ''
              [Interface]
              Address = 10.10.10.5/24
              ListenPort = 51820
              PrivateKey = WIREGUARD_PRIVATE_KEY
              [Peer]
              # Name = Server
              PublicKey = PEER_PUBLIC_KEY
              AllowedIPs = 10.10.10.0
              Endpoint = PEER_IP:PORT
            '';
            mode = "0600";
        };
        */
        ghaf.storagevm.directories = [
          {
            directory = "/etc/wireguard/";
            mode = "u=rwx,g=,o=";
          }
        ];
        ghaf.storagevm.files = [ "/etc/wireguard/wg0.conf" ];

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

        ghaf = {
          givc.appvm = {
            enable = true;
            name = lib.mkForce "business-vm";
            applications = [
              {
                name = "chromium";
                command = "${config.ghaf.givc.appPrefix}/run-waypipe ${config.ghaf.givc.appPrefix}/chromium --enable-features=UseOzonePlatform --ozone-platform=wayland ${config.ghaf.givc.idsExtraArgs} --load-extension=${pkgs.open-normal-extension}";
                args = [ "url" ];
              }
              {
                name = "outlook";
                command = "${config.ghaf.givc.appPrefix}/run-waypipe ${config.ghaf.givc.appPrefix}/chromium --enable-features=UseOzonePlatform --ozone-platform=wayland --app=https://outlook.office.com/mail/ ${config.ghaf.givc.idsExtraArgs} --load-extension=${pkgs.open-normal-extension}";
              }
              {
                name = "office";
                command = "${config.ghaf.givc.appPrefix}/run-waypipe ${config.ghaf.givc.appPrefix}/chromium --enable-features=UseOzonePlatform --ozone-platform=wayland --app=https://microsoft365.com ${config.ghaf.givc.idsExtraArgs} --load-extension=${pkgs.open-normal-extension}";
              }
              {
                name = "teams";
                command = "${config.ghaf.givc.appPrefix}/run-waypipe ${config.ghaf.givc.appPrefix}/chromium --enable-features=UseOzonePlatform --ozone-platform=wayland --app=https://teams.microsoft.com ${config.ghaf.givc.idsExtraArgs} --load-extension=${pkgs.open-normal-extension}";
              }
              {
                name = "gpclient";
                command = "${config.ghaf.givc.appPrefix}/run-waypipe ${config.ghaf.givc.appPrefix}/gpclient -platform wayland";
              }
              {
                name = "gnome-text-editor";
                command = "${config.ghaf.givc.appPrefix}/run-waypipe ${config.ghaf.givc.appPrefix}/gnome-text-editor";
              }
              {
                name = "losslesscut";
                command = "${config.ghaf.givc.appPrefix}/run-waypipe ${config.ghaf.givc.appPrefix}/losslesscut --enable-features=UseOzonePlatform --ozone-platform=wayland";
              }
              {
                name = "xarchiver";
                command = "${config.ghaf.givc.appPrefix}/run-waypipe ${config.ghaf.givc.appPrefix}/xarchiver";
              }
              {
                name = "wireguard-gui-launcher";
                command = "${config.ghaf.givc.appPrefix}/run-waypipe ${config.ghaf.givc.appPrefix}/wireguard-gui-launcher";
              }
            ];
          };

          reference = {
            programs.chromium.enable = true;

            services.globalprotect = {
              enable = true;
              csdWrapper = "${pkgs.openconnect}/libexec/openconnect/hipreport.sh";
            };
          };

          services.xdghandlers.enable = true;
        };

        environment.etc."chromium/native-messaging-hosts/fi.ssrc.open_normal.json" =
          mkIf config.ghaf.givc.enable
            {
              source = "${pkgs.open-normal-extension}/fi.ssrc.open_normal.json";
            };
        environment.etc."open-normal-extension.cfg" = mkIf config.ghaf.givc.enable {
          text =
            let
              cliArgs = builtins.replaceStrings [ "\n" ] [ " " ] ''
                --name ${config.ghaf.givc.adminConfig.name}
                --addr ${config.ghaf.givc.adminConfig.addr}
                --port ${config.ghaf.givc.adminConfig.port}
                ${optionalString config.ghaf.givc.enableTls "--cacert /run/givc/ca-cert.pem"}
                ${optionalString config.ghaf.givc.enableTls "--cert /run/givc/business-vm-cert.pem"}
                ${optionalString config.ghaf.givc.enableTls "--key /run/givc/business-vm-key.pem"}
                ${optionalString (!config.ghaf.givc.enableTls) "--notls"}
              '';
            in
            ''
              export GIVC_PATH="${pkgs.givc-cli}"
              export GIVC_OPTS="${cliArgs}"
            '';
        };

        # Enable dconf and icon pack for gnome text editor
        programs.dconf.enable = true;
        environment.systemPackages = [ pkgs.adwaita-icon-theme ];

        #Firewall Settings
        networking = {
          proxy = {
            default = "http://${netvmAddress}:${toString config.ghaf.reference.services.proxy-server.bindPort}";
            noProxy = "192.168.101.10,${adminvmAddress},127.0.0.1,localhost,${vpnOnlyAddr}";
          };
          firewall = {
            enable = true;
            extraCommands = ''

              add_rule() {
                    local ip=$1
                    iptables -I OUTPUT -p tcp -d $ip --dport 80 -j ACCEPT
                    iptables -I OUTPUT -p tcp -d $ip --dport 443 -j ACCEPT
                    iptables -I INPUT -p tcp -s $ip --sport 80 -j ACCEPT
                    iptables -I INPUT -p tcp -s $ip --sport 443 -j ACCEPT
                  }
              # Default policy
              iptables -P INPUT DROP

              # Block any other unwanted traffic (optional)
              iptables -N logreject
              iptables -A logreject -j LOG
              iptables -A logreject -j REJECT

              # allow everything for local VPN traffic
              iptables -A INPUT -i tun0 -j ACCEPT
              iptables -A FORWARD -i tun0 -j ACCEPT
              iptables -A FORWARD -o tun0 -j ACCEPT
              iptables -A OUTPUT -o tun0 -j ACCEPT

              # WARN: if all the traffic including VPN flowing through proxy is intended,
              # remove "add_rule 151.253.154.18" rule and pass "--proxy-server=http://192.168.100.1:3128" to openconnect(VPN) app.
              # also remove "151.253.154.18,tii.ae,.tii.ae,sapsf.com,.sapsf.com" addresses from noProxy option and add
              # them to allow acl list in modules/reference/appvms/3proxy-config.nix file.
              # Allow VPN access.tii.ae
              add_rule ${tiiVpnAddr}

              # Block all other HTTP and HTTPS traffic
              iptables -A OUTPUT -p tcp --dport 80 -j logreject
              iptables -A OUTPUT -p tcp --dport 443 -j logreject
              iptables -A OUTPUT -p udp --dport 80 -j logreject
              iptables -A OUTPUT -p udp --dport 443 -j logreject

            '';
          };
        };
      }
    )
  ];
  borderColor = "#00FF00";
  ghafAudio.enable = true;
  vtpm.enable = true;
}
