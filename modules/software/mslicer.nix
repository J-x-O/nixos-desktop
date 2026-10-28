{ vars, pkgs, lib, config, ... }:
let
  # nixpkgs still ships 0.6.0, which only speaks SDCP V1 (MQTT).
  # The Saturn 4 Ultra 16K uses SDCP V3 (websocket on :3030), added in 0.9.0.
  mslicer = pkgs.mslicer.overrideAttrs (old: rec {
    version = "0.9.2";
    src = pkgs.fetchFromGitHub {
      owner = "connorslade";
      repo = "mslicer";
      rev = "v${version}";
      hash = "sha256-qAWUSjfhz4iQ5JkFoxTPP3hQZ9q4i7Gtx4tmfgk5YvY=";
    };
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-g1RDUqmVjqvzh32B7m8zA6JmP4bsHKqptGzNoH0QzT8=";
    };
    # dist/msla_format is only valid after its generate.sh packaging step
    cargoBuildFlags = [ "--workspace" "--exclude" "msla_format" ];
    cargoTestFlags = cargoBuildFlags;

    # desktop entry + icon shipped for the flatpak
    postInstall = (old.postInstall or "") + ''
      install -Dm644 dist/flatpak/com.connorcode.mslicer.desktop -t $out/share/applications
      install -Dm644 dist/icon.svg $out/share/icons/hicolor/scalable/apps/com.connorcode.mslicer.svg
    '';
  });
in {
  options.myHome.mslicer.enable = lib.mkEnableOption "mslicer" // { default = true; };

  config = lib.mkIf config.myHome.mslicer.enable {
    home-manager.users.${vars.username} = {
      home.packages = [ mslicer ];
    };
  };
}
