# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{pkgs, ...}: let
  authorizedKeys = [
    # Add your SSH Public Keys here
    # "ssh-ed25519 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA user@host"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ1hVv5ryUbKkBaIrMvkjX8qq+7NLK1XJGB01FAnxRzs risto.kuusela@unikie.com"
  ];
in {
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;
  users.users.ghaf.openssh.authorizedKeys.keys = authorizedKeys;
}
