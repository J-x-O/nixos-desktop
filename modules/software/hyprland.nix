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

    # nixpkgs moved kde-material-you-colors out of python3Packages into a top-level by-name
    # package (v2.2.0, which now pulls python-magic and pywal16 itself, so the old dependency
    # patch is obsolete). illogical-impulse's python3.withPackages still asks for it by the old
    # name, and that env's bin/ is what puts the kde-material-you-colors daemon on PATH, so
    # re-expose the top-level package under python3Packages rather than patching the pinned flake.
    nixpkgs.overlays = [
      (final: prev: {
        python3 = prev.python3.override {
          packageOverrides = _: _: {
            kde-material-you-colors = prev.kde-material-you-colors;
          };
        };
      })
    ];

    home-manager.users.${vars.username} = {
      imports = [ inputs.illogical-flake.homeManagerModules.default ];
      programs.illogical-impulse.enable = true;

      xdg.configFile."hypr/custom/keybinds.lua" = lib.mkOverride 0 {
        text = ''
          hl.bind("SUPER + W", hl.dsp.exec_cmd("zen-beta"), { description = "Browser" })

          -- terminal binds: in dolphin, fire its own "Open Terminal" (Shift+F4) so the terminal starts in
          -- the folder that window shows (dolphin launches TerminalApplication from kdeglobals).
          -- explicit down/up instead of send_shortcut: that one marks the bind release-pending, so the
          -- function runs again on key release, sees the new terminal focused and opens a second one
          local function terminal_here()
            local win = hl.get_active_window()
            if win and win.class == "org.kde.dolphin" then
              hl.dispatch(hl.dsp.send_key_state({ mods = "SHIFT", key = "F4", state = "down", window = win }))
              hl.dispatch(hl.dsp.send_key_state({ mods = "SHIFT", key = "F4", state = "up", window = win }))
            else
              hl.dispatch(hl.dsp.exec_cmd(terminal))
            end
          end
          for _, keys in ipairs({ "SUPER + Return", "SUPER + T", "CTRL + ALT + T" }) do
            hl.unbind(keys)
            hl.bind(keys, terminal_here, keys == "SUPER + Return" and { description = "App: Terminal" } or nil)
          end
        '';
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "inode/directory" = "org.kde.dolphin.desktop";
          "text/html" = "zen-beta.desktop";
          "x-scheme-handler/http" = "zen-beta.desktop";
          "x-scheme-handler/https" = "zen-beta.desktop";
          "x-scheme-handler/about" = "zen-beta.desktop";
          "x-scheme-handler/unknown" = "zen-beta.desktop";
          "application/xhtml+xml" = "zen-beta.desktop";
          "application/x-extension-htm" = "zen-beta.desktop";
          "application/x-extension-html" = "zen-beta.desktop";
          "application/x-extension-xhtml" = "zen-beta.desktop";
        };
      };

      xdg.configFile."hypr/custom/execs.lua" = lib.mkOverride 0 {
        text = ''
          hl.on("hyprland.start", function ()
            -- start-hyprland doesn't activate graphical-session.target, and xdg-desktop-portal is
            -- Requisite= on it, so file pickers fail without this. Import the env first so the portal sees it.
            hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE && systemctl --user start nixos-fake-graphical-session.target")
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
