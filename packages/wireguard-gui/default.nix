{ wrapGAppsHook, fetchFromGitHub, lib, rustPlatform, pkg-config, wireguard-tools, glib, gtk4, polkit }:
rustPlatform.buildRustPackage rec {
  pname = "wireguard-gui";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "riskuuse";
    repo = pname;
    rev = "a57749b3893cfc654c34bd8f5782dc2f9248cdd7";
    # rev = "4d425258aa247e4c4344d5e52b2a054d4d6ba56a";
    # rev = "5fc785d7e989f5d091b6376c55bf7b03e3bc2e68";
    # rev = "bde638ceac2a6c1623ee08b138f852fba9dddc5d";
    # rev = "084522913a393a1c38ed088fa995560f35b10ac0";
    # rev = "5efd2c41b466616444d4acb341887e1197c8e801";
    # rev = "ab5083daf9fb8fb4c0e349882d2554aca1286ec2";
    sha256 = "sha256-LEOP2wKovsj8NZ7UVX86f+hwmVRYay+rRjOinDKQcD0=";
    # sha256 = "sha256-GYIhYt6gIchsjUKtpbrGqdnDHDrl+CKj3OYmVj4m5hQ=";
    # sha256 = "sha256-0NvRJCu9gShgYu30ClBBn/aM3ROywqm2zmLimzzNbDY=";
    # sha256 = "sha256-5ujwtgsOQwRQRTdOhX/RY9MEEBJpT5Nzy5gH1nMBuTU=";
    # sha256 = "sha256-kjLoDCX9k7oolZhhlsAF1QJmrcWaHdU11zGLrViOF4w=";
    # sha256 = "sha256-lZqPCFcbkdZmoowYX0yG37oe+2HuaYmCTwsl84LHRV8=";
    # sha256 = "sha256-+E7mnhe6uaJVgETWEfIrCfAhSRamPlMcxG6P3BDGneE=";
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
  cargoSha256 = "sha256-XO/saJfdiawN8CF6oF5HqrvLBllNueFUiE+7A7XWC5M=";
  # cargoSha256 = "sha256-XO/saJfdiawN8CF6oF5HqrvLBllNueFUiE+7A7XWC5M=";
  # cargoSha256 = "sha256-5ZOsTNtY3l0+xrFEJLTZeSXLLxUJ8N84GbmC1h7lzO0=";
  # cargoSha256 = "sha256-5ZOsTNtY3l0+xrFEJLTZeSXLLxUJ8N84GbmC1h7lzO0=";
  # cargoSha256 = "sha256-rV+GAOd3BmbMZKDKRDFNzrSbi5IqptNoFo9wHRDBPT0=";
  # cargoSha256 = "";
}