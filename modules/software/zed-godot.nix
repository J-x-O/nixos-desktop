{ vars, pkgs, lib, zed-netcoredbg, ... }:
{
  environment.systemPackages = with pkgs; [
    netcoredbg
    gcc
  ];

  home-manager.users.${vars.username} = { lib, ... }: {
    home.packages = with pkgs; [ rustup ];

    home.activation.setupRustup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      STAMP="$HOME/.local/share/zed-netcoredbg/.nix-source"
      CURRENT="${zed-netcoredbg}"
      if [ "$(cat $STAMP 2>/dev/null)" != "$CURRENT" ]; then
        $DRY_RUN_CMD rm -rf "$HOME/.local/share/zed-netcoredbg"
        $DRY_RUN_CMD mkdir -p "$HOME/.local/share/zed-netcoredbg"
        $DRY_RUN_CMD cp -r ${zed-netcoredbg}/. "$HOME/.local/share/zed-netcoredbg"
        $DRY_RUN_CMD chmod -R u+w "$HOME/.local/share/zed-netcoredbg"
        $DRY_RUN_CMD echo "$CURRENT" > "$HOME/.local/share/zed-netcoredbg/.nix-source"
      fi
      $DRY_RUN_CMD ${pkgs.rustup}/bin/rustup default stable
      $DRY_RUN_CMD ${pkgs.rustup}/bin/rustup target add wasm32-wasip1
    '';

    programs.zed-editor.userSettings.dap = {
      netcoredbg = {
        binary = "${pkgs.netcoredbg}/bin/netcoredbg";
        args = [ ];
      };
    };
  };
}
