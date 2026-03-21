{ vars, pkgs, ... }: {
  options.myHome.proton-mail.enable = lib.mkEnableOption "shared packages" // { default = true; };

  config = lib.mkIf config.myHome.proton-mail.enable {
    home-manager.users.${vars.username} = {
      home.packages = [ pkgs.protonmail-desktop ];
      xdg.dataFile."applications/proton-mail.desktop".source =
        "${pkgs.protonmail-desktop}/share/applications/proton-mail.desktop";
    };
  };
}
