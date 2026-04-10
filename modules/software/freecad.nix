{ vars, inputs, pkgs, lib, config, ... }:
let
  # freecad requires zippy for FCStd diffing
  zippey = pkgs.stdenvNoCC.mkDerivation {
    name = "zippey";
    src = pkgs.fetchFromBitbucket {
      owner = "sippey";
      repo = "zippey";
      rev = "f037ce9e9b968fa053f95cd2804a248021ffcb41";
      hash = "sha256-kFHC1VDh8KI17owOcmOoGlW7v4oxpYYPrkvGuzC4XfA=";
    };
    installPhase = ''
      mkdir -p $out/bin
      cp zippey.py $out/bin/zippey.py
      chmod +x $out/bin/zippey.py
    '';
  };
in {
  options.myHome.freecad.enable = lib.mkEnableOption "freecad" // { default = true; };
  config = lib.mkIf config.myHome.freecad.enable {
    home-manager.users.${vars.username} = {
      home.packages = with pkgs; [
        freecad
      ];
      programs.git = {
        enable = true;

        settings = {
          diff.zip.textconv = "unzip -c -a";
          filter.zippey = {
            smudge = "${zippey}/bin/zippey.py d";
            clean  = "${zippey}/bin/zippey.py e";
          };
        };

        attributes = [
          "*.FCStd filter=zippey"
          "*.FCStd diff=zip"
        ];
      };
    };
  };
}
