{ vars, pkgs, lib, config, ... }:
let
  # Craft apps (https://getartcraft.com) + SolidCraft, wrapped from their official AppImages.
  # update: ./update.sh regenerates sources.json from the latest GitHub releases
  sources = lib.importJSON ./sources.json;

  mkCraftApp = pname: { version, url, hash }:
    let
      src = pkgs.fetchurl { inherit url hash; };
      extracted = pkgs.appimageTools.extract { inherit pname version src; };
    in {
      # headless <app>-cli (convert/run/batch/mcp/...). plain rust binaries that only need libc/libgcc,
      # so patchelf them instead of a bwrap FHS env (that one can't chdir into e.g. /etc/nixos)
      cli = pkgs.stdenv.mkDerivation {
        pname = "${pname}-cli";
        inherit version;
        src = extracted;
        nativeBuildInputs = [ pkgs.autoPatchelfHook ];
        buildInputs = [ pkgs.stdenv.cc.cc.lib ];
        installPhase = ''
          mkdir -p $out/bin $out/share
          cp usr/bin/*-cli $out/bin/
          for dir in man fish zsh bash-completion; do
            if [ -d usr/share/$dir ]; then cp -r usr/share/$dir $out/share/; fi
          done
        '';
        meta.mainProgram = "${pname}-cli";
      };
      # wrapAppImage on the already extracted tree, so each AppImage is only unpacked once
      gui = pkgs.appimageTools.wrapAppImage {
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
    };

  apps = lib.mapAttrs mkCraftApp sources;
  cfg = config.myHome.craft;

  home = config.home-manager.users.${vars.username}.home.homeDirectory;
  # the apps don't agree on flags: most confine file access to automation roots (none granted
  # without them), solidcraft has --allow-path, the rest have no file confinement at all
  roots = [ "--automation-read-root" home "--automation-write-root" home ];
  mcpArgs = {
    solidcraft = [ "--headless" "--allow-path" home ];
    filmcraft = [ ];
    lightcraft = [ ];
    gridcraft = [ ];
    cadcraft = [ ];
  };

  # opencode's mcp schema takes one argv list instead of claude code's command + args pair
  opencodeMcp = lib.genAttrs cfg.apps (name: {
    type = "local";
    command = [ (lib.getExe apps.${name}.cli) "mcp" ] ++ (mcpArgs.${name} or roots);
    enabled = true;
  });
in {
  options.myHome.craft.apps = lib.mkOption {
    type = lib.types.listOf (lib.types.enum (lib.attrNames sources));
    default = [ ];
    example = [ "photocraft" "vectorcraft" "solidcraft" ];
    description = "Craft apps to install. Available: ${lib.concatStringsSep ", " (lib.attrNames sources)}";
  };

  config = lib.mkIf (cfg.apps != [ ]) {
    home-manager.users.${vars.username} = {
      programs.opencode.settings.mcp = opencodeMcp;

      home.packages = lib.concatMap (name: [ apps.${name}.gui apps.${name}.cli ]) cfg.apps;

      # register every installed app's MCP server (`<app>-cli mcp`, headless engine) in Claude Code's
      # user scope. ~/.claude.json is mutable state, so merge into it instead of owning the file;
      # craft entries for apps that got removed from cfg.apps are dropped again
      home.activation.claudeCraftMcp = let
        servers = lib.genAttrs cfg.apps (name: {
          type = "stdio";
          command = lib.getExe apps.${name}.cli;
          args = [ "mcp" ] ++ (mcpArgs.${name} or roots);
        });
        serversJson = pkgs.writeText "craft-mcp.json" (builtins.toJSON servers);
        allNames = builtins.toJSON (lib.attrNames sources);
      in {
        after = [ "writeBoundary" ];
        before = [ ];
        data = ''
          f="$HOME/.claude.json"
          [ -s "$f" ] || echo '{}' > "$f"
          tmp=$(mktemp)
          ${lib.getExe pkgs.jq} --slurpfile new ${serversJson} --argjson all '${allNames}' \
            '.mcpServers = (((.mcpServers // {}) | with_entries(select(.key as $k | $all | index($k) | not))) + $new[0])' \
            "$f" > "$tmp" && cat "$tmp" > "$f"
          rm -f "$tmp"
        '';
      };
    };
  };
}
