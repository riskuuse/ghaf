{ wrapGAppsHook, fetchFromGitHub, lib, rustPlatform, pkg-config, wireguard-tools, glib, gtk4, polkit }:
rustPlatform.buildRustPackage rec {
  pname = "wireguard-gui";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "riskuuse";
    repo = pname;
    rev = "a57749b3893cfc654c34bd8f5782dc2f9248cdd7";
    sha256 = "sha256-LEOP2wKovsj8NZ7UVX86f+hwmVRYay+rRjOinDKQcD0=";
    # sha256 = lib.fakeSha256;
  };

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook
  ];

  buildInputs = [
    wireguard-tools
    glib.dev
    gtk4.dev
    polkit
  ];

  postFixup = ''
    wrapProgram $out/bin/${pname} \
       --set LIBGL_ALWAYS_SOFTWARE true \
       --set G_MESSAGES_DEBUG all
  '';
  cargoHash = "sha256-XO/saJfdiawN8CF6oF5HqrvLBllNueFUiE+7A7XWC5M=";
  # cargoSha256 = "";
}