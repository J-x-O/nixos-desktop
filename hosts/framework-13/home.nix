{ illogical-flake, inputs, ... }: {
  imports = [
    ../../modules/software
    ../../modules/common.nix
    ../../modules/home.nix
    ../../modules/security.nix
    ../../modules/session.nix
  ];
  
  myHome = {
    hyprland = {
      monitors = [
        "desc:AOC 24B31H AUYR39A004844,preferred,-3840x0,1,"
        "desc:AOC 24B31H AUYR39A004842,preferred,-1920x0,1"
        "eDP-1,preferred,0x0,1.666667,transform, 0"
      ];
    };
  };
  home-manager.backupFileExtension = "backup";
}
