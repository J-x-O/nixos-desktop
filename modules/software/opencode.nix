# provider-agnostic agent CLI (https://opencode.ai), installed alongside claude-code so there is a
# working agent on deepseek when claude's limits kick in. it does not read ~/.claude.json: its config
# lives in ~/.config/opencode/opencode.json (generated below) and its api keys in
# ~/.local/share/opencode/auth.json, which `/connect` writes, so no secret ever touches the nix store.
{ vars, pkgs, lib, config, ... }:
let
  cfg = config.myHome.opencode;
in {
  options.myHome.opencode = {
    enable = lib.mkEnableOption "opencode" // { default = true; };

    model = lib.mkOption {
      type = lib.types.str;
      default = "deepseek/deepseek-v4-pro";
      description = "Session model. `/models` in the TUI switches it without touching this.";
    };

    smallModel = lib.mkOption {
      type = lib.types.str;
      default = "deepseek/deepseek-flash";
      description = "Model for titles, summaries and other background work.";
    };

    mcp = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = ''
        MCP servers in opencode's `mcp` schema. Other modules (see craft) contribute their
        servers here; unlike claude code's ~/.claude.json this file is owned wholesale, so
        entries for removed apps disappear on their own.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # The bun-built `node_modules` fixed-output derivation in this nixpkgs rev doesn't
    # reproduce here: bun writes a different tree than the pinned outputHash, so opencode
    # refuses to build. Upstream HEAD carries the same hash, so bumping nixpkgs won't fix
    # it; the tree still comes from this repo's own bun.lock, we're only re-asserting the
    # hash of what that fetch actually produced. Drop this if a later rev builds cleanly.
    nixpkgs.overlays = [
      (_: prev: {
        opencode = prev.opencode.overrideAttrs (old: {
          node_modules = old.node_modules.overrideAttrs (_: {
            outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
          });
        });
      })
    ];

    home-manager.users.${vars.username}.xdg.configFile."opencode/opencode.json".source =
      (pkgs.formats.json { }).generate "opencode.json" {
        "$schema" = "https://opencode.ai/config.json";
        inherit (cfg) model mcp;
        small_model = cfg.smallModel;
      };
  };
}
