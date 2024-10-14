{ wrapGAppsHook, fetchFromGitHub, lib, rustPlatform, pkg-config, wireguard-tools, glib, gtk4, polkit }:
rustPlatform.buildRustPackage rec {
  pname = "wireguard-gui";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "riskuuse";
    repo = pname;
    # rev = "a57749b3893cfc654c34bd8f5782dc2f9248cdd7";
    # rev = "e5455abb28fae4473005732be2fffc0b75677baa";
    rev = "c0666fc41cafd3f80dab78718b748ee73cdfdaff";
    # rev = "bec9063bab14f0d97558c58824f3e00f7ebff5d0";
    # rev = "0576ed985cbb137bfe910be3ade82aeb1970438b";
    # sha256 = "sha256-LEOP2wKovsj8NZ7UVX86f+hwmVRYay+rRjOinDKQcD0=";
    # sha256 = "sha256-8nJnLy6e76MPVb5W2PpLIe030phkTkmc7d2UHofiO9I=";
    sha256 = "sha256-77VcAU2p9ViwMarcUn7WdottL4lQRHEO/QYS68op6UQ=";
    # sha256 = "sha256-bGGdop1Ej+D51XvobPq7qrNyzsAnng5ePYMWQ/p8LPo=";
    # sha256 = "sha256-H7vIlcSvHr4dpwn9Y5eERagzCf8tqaMpKuhXbuDlOL0=";
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