{ vars, photogimp, pkgs, lib, config, ... }: {
  
  options.myHome.gimp.enable = lib.mkEnableOption "shared packages" // { default = true; };
  
  config = lib.mkIf config.myHome.gimp.enable {
    home-manager.users.${vars.username} = {
      home.packages = [ pkgs.gimp ];
    
      home.file.".config/GIMP/3.0" = {
        source = "${photogimp}/.config/GIMP/3.0";
        recursive = true;
        force = true;
      };
    };
  };
}