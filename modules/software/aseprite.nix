# aseprite + diivi/aseprite-mcp (https://github.com/diivi/aseprite-mcp), hooked up to opencode and claude code.
# no nixpkgs / mcp-servers-nix package exists for it, so it's packaged here (plain python, run as `python -m aseprite_mcp`).
{ vars, pkgs, lib, config, ... }:
let
  # mcp 2 (nixpkgs default) dropped mcp.server.fastmcp, which this server imports, so use the 1.x line
  aseprite-mcp = pkgs.stdenv.mkDerivation {
    pname = "aseprite-mcp";
    version = "0.1.0-unstable-4bcdb6f";
    src = pkgs.fetchFromGitHub {
      owner = "diivi";
      repo = "aseprite-mcp";
      rev = "4bcdb6f5932116bbdbd1b7d3fcc1e8f965f7657a";
      hash = "sha256-RzmKOVsSYcnTnuNn7qu/zu7FwrIV1lJ0Sv5JYisUVaE=";
    };
    nativeBuildInputs = [ pkgs.makeWrapper ];
    installPhase = ''
      mkdir -p $out/lib $out/bin
      cp -r aseprite_mcp $out/lib/
      makeWrapper ${pkgs.python3.withPackages (ps: [ ps.mcp_1 ps.httpx ps.pillow ps.python-dotenv ])}/bin/python $out/bin/aseprite-mcp \
        --add-flags "-m aseprite_mcp" \
        --prefix PYTHONPATH : $out/lib \
        --set-default ASEPRITE_PATH ${lib.getExe pkgs.aseprite}
    '';
    meta.mainProgram = "aseprite-mcp";
  };
  mcpBin = lib.getExe aseprite-mcp;
in {

  options.myHome.aseprite.enable = lib.mkEnableOption "aseprite" // { default = true; };

  config = lib.mkIf config.myHome.aseprite.enable {
    home-manager.users.${vars.username} = {
      home.packages = [ pkgs.aseprite aseprite-mcp ];

      programs.opencode.settings.mcp.aseprite = {
        type = "local";
        command = [ mcpBin ];
        enabled = true;
      };

      # same merge-into-~/.claude.json approach as craft/default.nix (the file is mutable claude state)
      home.activation.claudeAsepriteMcp = {
        after = [ "writeBoundary" ];
        before = [ ];
        data = ''
          f="$HOME/.claude.json"
          [ -s "$f" ] || echo '{}' > "$f"
          tmp=$(mktemp)
          ${lib.getExe pkgs.jq} '.mcpServers.aseprite = {type: "stdio", command: "${mcpBin}", args: []}' \
            "$f" > "$tmp" && cat "$tmp" > "$f"
          rm -f "$tmp"
        '';
      };
    };
  };
}
