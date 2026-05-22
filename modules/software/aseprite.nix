{ vars, pkgs, lib, config, ... }: {

  options.myHome.aseprite.enable = lib.mkEnableOption "aseprite" // { default = true; };

  config = lib.mkIf config.myHome.aseprite.enable {
    home-manager.users.${vars.username} = {
      home.packages = [ pkgs.aseprite ];
    };
  };
}
