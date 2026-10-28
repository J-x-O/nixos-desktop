{ vars, pkgs, lib, config, ... }:
let
  # Craft apps (https://getartcraft.com) + SolidCraft, wrapped from their official AppImages.
  # update: ./update.sh regenerates sources.json from the latest GitHub releases
  sources = lib.importJSON ./sources.json;

  mkCraftApp = pname: { version, url, hash }:
    let
      src = pkgs.fetchurl { inherit url hash; };
      extracted = pkgs.appimageTools.extract { inherit pname version src; };
    # wrapAppImage on the already extracted tree, so each AppImage is only unpacked once
    in pkgs.appimageTools.wrapAppImage {
      inherit pname version;
      src = extracted;
      # ship the bundled desktop entries, icons and mime types so they show up in the launcher
      # (AppRun only self-integrates when started as a real AppImage, which we never do)
      extraInstallCommands = ''
        for dir in applications icons mime metainfo; do
          if [ -d ${extracted}/usr/share/$dir ]; then
            mkdir -p $out/share
            cp -r ${extracted}/usr/share/$dir $out/share/
          fi
        done
        chmod -R u+w $out/share
        for f in $out/share/applications/*.desktop; do
          sed -i -e 's|^Exec=AppRun|Exec=${pname}|' -e '/^TryExec=/d' "$f"
        done
      '';
      meta.mainProgram = pname;
    };

  apps = lib.mapAttrs mkCraftApp sources;
  cfg = config.myHome.craft;
in {
  options.myHome.craft.apps = lib.mkOption {
    type = lib.types.listOf (lib.types.enum (lib.attrNames sources));
    default = [ ];
    example = [ "photocraft" "vectorcraft" "solidcraft" ];
    description = "Craft apps to install. Available: ${lib.concatStringsSep ", " (lib.attrNames sources)}";
  };

  config = lib.mkIf (cfg.apps != [ ]) {
    home-manager.users.${vars.username} = {
      home.packages = map (name: apps.${name}) cfg.apps;
    };
  };
}
