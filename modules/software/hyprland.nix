{ vars, inputs, pkgs, config, lib, ... }: {

  options.myHome.hyprland = {
    enable = lib.mkEnableOption "hyprland with illogical-impulse" // { default = true; };
    monitors = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          output = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Monitor name/description (e.g. \"eDP-1\" or \"desc:...\"); empty matches all monitors.";
          };
          mode = lib.mkOption {
            type = lib.types.str;
            default = "preferred";
          };
          position = lib.mkOption {
            type = lib.types.str;
            default = "auto";
          };
          scale = lib.mkOption {
            type = with lib.types; either (either int float) str;
            default = 1;
          };
          transform = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
          };
        };
      });
      default = [];
    };
  };

  config = lib.mkIf config.myHome.hyprland.enable {

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
      programs.illogical-impulse.enable = true;

      xdg.configFile."hypr/custom/keybinds.lua" = lib.mkOverride 0 {
        text = ''
          hl.bind("SUPER + W", hl.dsp.exec_cmd("zen"), { description = "Browser" })
        '';
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "inode/directory" = "org.kde.dolphin.desktop";
          "text/html" = "zen.desktop";
          "x-scheme-handler/http" = "zen.desktop";
          "x-scheme-handler/https" = "zen.desktop";
          "x-scheme-handler/about" = "zen.desktop";
          "x-scheme-handler/unknown" = "zen.desktop";
          "application/xhtml+xml" = "zen.desktop";
          "application/x-extension-htm" = "zen.desktop";
          "application/x-extension-html" = "zen.desktop";
          "application/x-extension-xhtml" = "zen.desktop";
        };
      };

      xdg.configFile."hypr/custom/execs.lua" = lib.mkOverride 0 {
        text = ''
          hl.on("hyprland.start", function ()
            hl.exec_cmd("kdeconnect-indicator")
          end)
        '';
      };

      xdg.configFile."hypr/custom/rules.lua" = lib.mkOverride 0 {
        text = ''
          hl.window_rule({ match = { class = "^(blender)$", title = "^(Blender File View)$" }, min_size = {900, 500} })
          hl.window_rule({ match = { class = "^(Unity)$", title = "^(Select .*)$" }, tag = "under_cursor" })
          hl.window_rule({ match = { class = "^(Unity)$", title = "^(Color)$" }, tag = "under_cursor" })
          hl.window_rule({ match = { class = "^(Unity)$", title = "^(UnityEditor.Searcher.SearcherWindow)$" }, tag = "under_cursor" })
          hl.window_rule({ match = { class = "^(Unity)$", title = "^(.*Gradient Editor.*)$" }, tag = "under_cursor" })
          hl.window_rule({ match = { tag = "under_cursor" }, move = {"max(min(cursor_x,monitor_w-window_w),0)", "max(min(cursor_y,monitor_h-window_h),0)"} })
        '';
      };

      xdg.configFile."hypr/custom/general.lua" = lib.mkOverride 0 {
        text = let
          luaValue = v: if builtins.isString v then ''"${v}"'' else toString v;
        in ''
          ${lib.concatMapStrings (m: ''
            hl.monitor({ output = "${m.output}", mode = "${m.mode}", position = "${m.position}", scale = ${luaValue m.scale}${lib.optionalString (m.transform != null) ", transform = ${toString m.transform}"} })
          '') config.myHome.hyprland.monitors}
          hl.config({ input = { kb_layout = "de" } })
        '';
      };
    };
  };
}
