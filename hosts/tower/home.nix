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
        "desc:BNQ BenQ GL2450 R4E01733019,preferred,0x0,1"
        "desc:BNQ BenQ GL2450H S5D02889019,preferred,-1920x0,1"
      ];
    };
  };
  home-manager.backupFileExtension = "backup";
}
