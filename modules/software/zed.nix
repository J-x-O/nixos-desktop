{ vars, pkgs, ... }: {
  options.myHome.zed.enable = lib.mkEnableOption "shared packages"; // { default = true; };
  
  config = lib.mkIf config.myHome.zed.enable {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc.lib zlib openssl icu
    ];
  
    home-manager.users.${vars.username} = { 
      programs.zed-editor = {
        enable = true;
        extensions = [ "nix" "cs" "rust" ];
        userSettings = {
          theme = {
            mode = "system";
            dark = "One Dark";
            light = "One Light";
          };
          hour_format = "hour24";
          vim_mode = true;
        };
      };
    };
  };
}