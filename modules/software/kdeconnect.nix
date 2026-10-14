# KDE Connect, including remote input (phone as mouse/keyboard) on Hyprland
{ vars, inputs, pkgs, lib, config, ... }: let
  hyprlandEnabled = config.myHome.hyprland.enable;
in {
  imports = [ inputs.hypr-kdeconnect-fix.nixosModules.default ];

  options.myHome.kdeconnect.enable = lib.mkEnableOption "KDE Connect" // { default = true; };

  config = lib.mkIf config.myHome.kdeconnect.enable {
    programs.kdeconnect.enable = true;

    # Remote input goes through the RemoteDesktop portal, which xdph doesn't implement.
    # hypr-kdeconnect-fix does, without a permission prompt (it only accepts KDE Connect's app id)
    # and with ConnectToEIS. Replaced xdg-desktop-portal-luminous, which needed a click-to-allow
    # overlay every login, lacked ConnectToEIS and broke Backspace while a session was active.
    # TODO: switch to xdph once it ships RemoteDesktop upstream (hyprwm/xdg-desktop-portal-hyprland
    # PR #402 and follow-ups #426/#428), then drop this input and route RemoteDesktop to "hyprland".
    services.hypr-kdeconnect-fix.enable = true;

    # illogical-impulse copies its own hyprland-portals.conf over ~/.config every activation,
    # which shadows /etc/xdg; re-add the RemoteDesktop route (replacing any stale one).
    home-manager.users.${vars.username}.home.activation.portalRemoteDesktop =
      inputs.home-manager.lib.hm.dag.entryAfter (
        [ "writeBoundary" ] ++ lib.optional hyprlandEnabled "copyIllogicalImpulseConfigs"
      ) ''
        portalConf="$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"
        route="org.freedesktop.impl.portal.RemoteDesktop = hypr-kdeconnect"
        if [ -f "$portalConf" ] && ! grep -qxF "$route" "$portalConf"; then
          $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i '/impl\.portal\.RemoteDesktop/d' "$portalConf"
          $DRY_RUN_CMD bash -c "printf '%s\n' \"$route\" >> \"$portalConf\""
        fi
      '';
  };
}
