# opencode (https://opencode.ai): agent CLI on deepseek for when claude's limits kick in.
# api keys live in ~/.local/share/opencode/auth.json (written by `/connect`), never in the store.
# craft/default.nix adds its MCP servers via programs.opencode.settings.mcp.
{ vars, ... }: {
  # nixpkgs' opencode node_modules FOD hash is stale (bun writes a different tree), so the stock
  # package fails to build and isn't in cache.nixos.org. Drop once nixpkgs fixes the hash.
  nixpkgs.overlays = [
    (_: prev: {
      opencode = prev.opencode.overrideAttrs (old: {
        node_modules = old.node_modules.overrideAttrs (_: {
          outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
        });
      });
    })
  ];

  home-manager.users.${vars.username}.programs.opencode = {
    enable = true;
    settings = {
      model = "deepseek/deepseek-v4-pro";
      small_model = "deepseek/deepseek-flash";
    };
  };
}
