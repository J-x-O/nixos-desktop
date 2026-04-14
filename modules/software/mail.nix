{ vars, pkgs, lib, config, ... }:
let
  mailspring-wrapped = pkgs.symlinkJoin {
    name = "mailspring";
    paths = [ pkgs.mailspring ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/mailspring \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
          pkgs.libglvnd
          pkgs.mesa
          pkgs.html-tidy
        ]}
    '';
  };
in {
  options.myHome.mail.enable = lib.mkEnableOption "shared packages" // { default = true; };

  config = lib.mkIf config.myHome.mail.enable {
    home-manager.users.${vars.username} = {
      home.packages = [ mailspring-wrapped ];

      xdg.configFile."Mailspring/packages/mailspring-mouse-fix".source = pkgs.fetchFromGitHub {
        owner = "J-x-O";
        repo = "mailspring-mouse-fix";
        rev = "7e10c735a79758ee216f4363538bbc136fce67e8";
        hash = "sha256-77XDIzDD+NQdtXd9P5z3wRdstRd5FyxkeRm0Kg9JXHA=";
      };

      xdg.desktopEntries.Mailspring = {
        name = "Mailspring";
        exec = "${mailspring-wrapped}/bin/mailspring --password-store=gnome-libsecret %U";
        icon = "mailspring";
        comment = "The best email app for people and teams at work";
        categories = [ "Network" "Email" ];
        mimeType = [ "x-scheme-handler/mailto" "x-scheme-handler/mailspring" ];
      };
    };
  };
}
