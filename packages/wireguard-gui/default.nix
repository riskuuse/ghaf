{ wrapGAppsHook4, fetchFromGitHub, lib, rustPlatform, pkg-config, wireguard-tools, glib, gtk4 }:
rustPlatform.buildRustPackage rec {
  pname = "wireguard-gui";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "remimimimimi";
    repo = pname;
    # rev = "5efd2c41b466616444d4acb341887e1197c8e801";
    rev = "ab5083daf9fb8fb4c0e349882d2554aca1286ec2";
    #sha256 = "sha256-lZqPCFcbkdZmoowYX0yG37oe+2HuaYmCTwsl84LHRV8=";
    sha256 = "sha256-+E7mnhe6uaJVgETWEfIrCfAhSRamPlMcxG6P3BDGneE=";
    # sha256 = lib.fakeSha256;
  };

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    wireguard-tools
    glib.dev
    gtk4.dev
  ];

  postFixup = ''
    wrapProgram $out/bin/${pname} \
       --set LIBGL_ALWAYS_SOFTWARE true \
       --set G_MESSAGES_DEBUG all
  '';

  cargoSha256 = "sha256-rV+GAOd3BmbMZKDKRDFNzrSbi5IqptNoFo9wHRDBPT0=";
}