{ inputs, pkgs, config, lib, ... }:
{
  imports = [ inputs.illogical-flake.homeManagerModules.default ];


  options.myHome.hyprland = {
    enable = lib.mkEnableOption "hyprland with illogical-impulse";
    monitors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ",preferred,auto,1" ];
    };
  };

  config = lib.mkIf config.myHome.hyprland.enable {
    programs.illogical-impulse.enable = true;

    wayland.windowManager.hyprland.extraConfig = ''
      ${lib.concatMapStrings (m: "monitor = ${m}\n") config.myhome.hyprland.monitors}

      input.kb_layout = de

      windowrule = match:class ^(blender)$, match:title ^(Blender File View)$, min_size 900 500
      windowrule = match:class ^(Unity)$, match:title ^(Select .*)$, tag under_cursor
      windowrule = match:class ^(Unity)$, match:title ^(.*Gradient Editor.*)$, tag under_cursor
      windowrule = match:class ^(Unity)$, match:title ^(Color)$, tag under_cursor
      windowrule = match:class ^(Unity)$, match:title ^(UnityEditor.Searcher.SearcherWindow)$, tag under_cursor
      windowrule {
        name = UnderCursor
        match:tag = under_cursor
        move = max(min(cursor_x,monitor_w-window_w),0) max(min(cursor_y,monitor_h-window_h),0)
      }
    '';
  };


}
