{ vars, photogimp, pkgs, ... }: {
  
  options.myHome.gimp.enable = lib.mkEnableOption "shared packages" // { default = true; };
  
  config = lib.mkIf config.myHome.gimp.enable {
    home-manager.users.${vars.username} = {
      home.packages = [ pkgs.gimp ];
    
      home.file.".config/GIMP/3.0" = {
        source = "${photogimp}/.var/app/org.gimp.GIMP/config/GIMP/3.0";
        recursive = true;
      };
      home.file.".local/share/GIMP/3.0" = {
        source = "${photogimp}/.var/app/org.gimp.GIMP/data/GIMP/3.0";
        recursive = true;
      };
    };
  }
}