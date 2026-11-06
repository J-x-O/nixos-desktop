# Blocks suspend while any MPRIS player (Spotify, browser, mpv, ...) is playing.
# hypridle still locks and turns off the screen; only its `systemctl suspend` gets refused by logind.
# Side effect: manual suspend is also refused while something plays, pause first.
{ pkgs, lib, config, ... }: let
  mediaInhibit = pkgs.writeShellApplication {
    name = "media-inhibit";
    runtimeInputs = [ pkgs.playerctl pkgs.systemd pkgs.coreutils pkgs.gnugrep ];
    text = ''
      inhibitor=""
      trap '[ -n "$inhibitor" ] && kill "$inhibitor" 2>/dev/null' EXIT

      while true; do
        if playerctl --all-players status 2>/dev/null | grep -qx Playing; then
          if [ -z "$inhibitor" ] || ! kill -0 "$inhibitor" 2>/dev/null; then
            systemd-inhibit --what=sleep --who=media-inhibit --why="Media is playing" --mode=block \
              sleep infinity &
            inhibitor=$!
          fi
        elif [ -n "$inhibitor" ]; then
          kill "$inhibitor" 2>/dev/null || true
          inhibitor=""
        fi
        sleep 30
      done
    '';
  };
in {
  options.myHome.mediaInhibit.enable = lib.mkEnableOption "suspend inhibitor while media plays" // { default = true; };

  config = lib.mkIf config.myHome.mediaInhibit.enable {
    systemd.user.services.media-inhibit = {
      description = "Block suspend while media is playing";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = lib.getExe mediaInhibit;
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
