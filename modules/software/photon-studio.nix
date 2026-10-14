{ vars, pkgs, lib, config, ... }:
let
  # not in nixpkgs, wrap the official AppImage
  # update: bump version, then `nix store prefetch-file <url>` for the new hash
  pname = "photon-studio";
  version = "0.1.43";
  src = pkgs.fetchurl {
    url = "https://downloads.tenzen.studio/photon/stable/linux/${version}/Photon-Studio-${version}-linux-x64.AppImage";
    hash = "sha256-Ojt0sQwwgx37sR7I3K7OzUUdHm98lwAGTBpHMY5xREE=";
  };
  extracted = pkgs.appimageTools.extract { inherit pname version src; };

  photon-studio = pkgs.appimageTools.wrapType2 {
    inherit pname version src;
    # install the bundled desktop entry + icon so it shows up in the launcher
    extraInstallCommands = ''
      install -Dm444 ${extracted}/photon-studio.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/photon-studio.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=photon-studio'
      install -Dm444 ${extracted}/usr/share/icons/hicolor/512x512/apps/photon-studio.png \
        -t $out/share/icons/hicolor/512x512/apps
    '';
  };
in {
  options.myHome.photon-studio.enable = lib.mkEnableOption "photon studio" // { default = true; };

  config = lib.mkIf config.myHome.photon-studio.enable {
    home-manager.users.${vars.username} = {
      home.packages = [ photon-studio ];
    };
  };
}
