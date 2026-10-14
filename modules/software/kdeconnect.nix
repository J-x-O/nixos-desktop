# KDE Connect, including remote input (phone as mouse/keyboard) on Hyprland
{ vars, inputs, pkgs, lib, config, ... }: let
  hyprlandEnabled = config.myHome.hyprland.enable;
in {
  options.myHome.kdeconnect.enable = lib.mkEnableOption "KDE Connect" // { default = true; };

  config = lib.mkIf config.myHome.kdeconnect.enable {
    programs.kdeconnect.enable = true;

    # Remote input goes through the RemoteDesktop portal, which xdph doesn't implement;
    # luminous does, so route only that interface to it.
    xdg.portal = {
      extraPortals = [ pkgs.xdg-desktop-portal-luminous ];
      config.hyprland."org.freedesktop.impl.portal.RemoteDesktop" = [ "luminous" ];
    };

    # illogical-impulse copies its own hyprland-portals.conf over ~/.config every activation,
    # which shadows /etc/xdg; re-add the RemoteDesktop route.
    home-manager.users.${vars.username}.home.activation.portalRemoteDesktop =
      inputs.home-manager.lib.hm.dag.entryAfter (
        [ "writeBoundary" ] ++ lib.optional hyprlandEnabled "copyIllogicalImpulseConfigs"
      ) ''
        portalConf="$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"
        if [ -f "$portalConf" ] && ! grep -q "impl.portal.RemoteDesktop" "$portalConf"; then
          $DRY_RUN_CMD bash -c "printf 'org.freedesktop.impl.portal.RemoteDesktop = luminous\n' >> \"$portalConf\""
        fi
      '';
  };
}
