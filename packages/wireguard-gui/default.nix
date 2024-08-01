{ wrapGAppsHook4, gsettings-desktop-schemas, fetchFromGitHub, lib, rustPlatform, pkg-config, wireguard-tools, glib, gtk4 }:
rustPlatform.buildRustPackage rec {
  pname = "wireguard-gui";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "remimimimimi";
    repo = pname;
    rev = "ab5083daf9fb8fb4c0e349882d2554aca1286ec2";
    # rev = "e1f17f284f8ac5789e569acb399ec30ad8f08268";
    # rev = version;
    sha256 = "sha256-+E7mnhe6uaJVgETWEfIrCfAhSRamPlMcxG6P3BDGneE=";
    # sha256 = "sha256-XS4zYzG6KghvyJUPeO53o6HAo6Upo8cHpw8f38UcKxo=";
    # sha256 = lib.fakeSha256;
  };

  nativeBuildInputs = [
    pkg-config
#    makeWrapper
    wrapGAppsHook4
  ];

  buildInputs = [
    wireguard-tools
    glib.dev
    gtk4.dev
    gsettings-desktop-schemas
  ];

#  postFixup = ''
#    wrapProgram $out/bin/${pname} \
#      --prefix XDG_DATA_DIRS : "$out/share" \
#      --prefix XDG_DATA_DIRS : "$out/share/gsettings-schemas/${gsettings-desktop-schemas.name}" \
#      --prefix XDG_DATA_DIRS : "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}" \
#      --prefix GSETTINGS_SCHEMA_DIR : "$out/share" \
#      --prefix GSETTINGS_SCHEMAS_PATH : "$out/share/glib-2.0/schemas"
#      #--set GSETTINGS_SCHEMAS_PATH ${gsettings-desktop-schemas}/share/gsettings-desktop-schemas/gsettings-schemas-46.0/glib-2.0/schemas/ \
#      #--set GSETTINGS_SCHEMA_DIR ${gsettings-desktop-schemas}/share/gsettings-desktop-schemas/gsettings-schemas-46.0/glib-2.0/schemas/  \
#      #--set XDG_DATA_DIRS ${gsettings-desktop-schemas}/share/gsettings-desktop-schemas/gsettings-schemas-46.0/glib-2.0/schemas/:$XDG_DATA_DIRS
#  '';

  cargoSha256 = "sha256-rV+GAOd3BmbMZKDKRDFNzrSbi5IqptNoFo9wHRDBPT0=";
}