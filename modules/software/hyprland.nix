{ vars, inputs, pkgs, config, lib, ... }: {

  options.myHome.hyprland = {
    enable = lib.mkEnableOption "hyprland with illogical-impulse" // { default = true; };
    monitors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ",preferred,auto,1" ];
    };
  };

  config = lib.mkIf config.myHome.hyprland.enable {
    
    programs.illogical-impulse.enable = true;
    
    # adds the relevant dependency which is broken in kde-material-you-colors package
    nixpkgs.overlays = [
      (final: prev: {
        python3 = prev.python3.override {
          packageOverrides = pyself: pysuper: {
            kde-material-you-colors = pysuper.kde-material-you-colors.overridePythonAttrs (old: {
              dependencies = (old.dependencies or []) ++ [ pyself.python-magic ];
            });
          };
        };
      })
    ];
    
    home-manager.users.${vars.username} = {
      imports = [ inputs.illogical-flake.homeManagerModules.default ];
      
      xdg.configFile."hypr/custom/rules.conf" = lib.mkOverride 0 {
        text = ''
          windowrule = match:class ^(blender)$, match:title ^(Blender File View)$, min_size 900 500
          windowrule = match:class ^(Unity)$, match:title ^(Select .*)$, tag under_cursor
          windowrule = match:class ^(Unity)$, match:title ^(Color)$, tag under_cursor
          windowrule = match:class ^(Unity)$, match:title ^(UnityEditor.Searcher.SearcherWindow)$, tag under_cursor
          windowrule = match:class ^(Unity)$, match:title ^(.*Gradient Editor.*)$, tag under_cursor
          windowrule {
            name = UnderCursor
            match:tag = under_cursor
            move = max(min(cursor_x,monitor_w-window_w),0) max(min(cursor_y,monitor_h-window_h),0)
          }
        '';
      };
    
      xdg.configFile."hypr/custom/general.conf" = lib.mkOverride 0 {
        text = ''
          ${lib.concatMapStrings (m: "monitor = ${m}\n") config.myHome.hyprland.monitors}
          input {
            kb_layout = de
          }
        '';
      };
    }
  };
}
