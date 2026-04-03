{ vars, pkgs, lib, config, ... }:
let
  mountType = lib.types.submodule {
    options = {
      remote = lib.mkOption {
        type = lib.types.str;
        default = "gdrive";
        description = "Name of the rclone remote (must exist in ~/.config/rclone/rclone.conf)";
      };
      remotePath = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Subdirectory within the remote (e.g. \"02_AREAS/05_JoyJab Arcades\")";
      };
      mountPoint = lib.mkOption {
        type = lib.types.str;
        description = "Local path to mount to (e.g. \"/home/jesco/JoyJab\")";
      };
    };
  };

  mkService = mount: {
    Unit = {
      Description = "rclone mount: ${mount.remote}:${mount.remotePath}";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mount.mountPoint}";
      ExecStart = "${pkgs.rclone}/bin/rclone mount \"${mount.remote}:${mount.remotePath}\" \"${mount.mountPoint}\" --vfs-cache-mode full --vfs-cache-max-size 2G --allow-other";
      ExecStop = "${pkgs.fuse3}/bin/fusermount3 -uz \"${mount.mountPoint}\"";
      Restart = "on-failure";
      RestartSec = "10s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Sanitize a string into a valid systemd service name
  toServiceName = s: lib.replaceStrings [ "/" " " ":" ] [ "-" "_" "-" ] s;
in
{
  options.myHome.rclone = {
    enable = lib.mkEnableOption "rclone mounts" // { default = true; };
    mounts = lib.mkOption {
      type = lib.types.listOf mountType;
      default = [];
      description = "List of rclone remotes to mount";
    };
  };

  config = lib.mkIf config.myHome.rclone.enable {
    programs.fuse.userAllowOther = true;

    environment.systemPackages = [ pkgs.fuse3 ];

    home-manager.users.${vars.username} = {
      home.packages = [ pkgs.rclone ];

      systemd.user.services = lib.listToAttrs (map (mount: {
        name = "rclone-${toServiceName "${mount.remote}-${mount.remotePath}"}";
        value = mkService mount;
      }) config.myHome.rclone.mounts);
    };
  };
}
