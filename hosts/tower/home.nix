{ illogical-flake, inputs, ... }: {
  home-manager.users.jesco = {
    imports = [
      ../../modules/home/common.nix
      inputs.zen-browser.homeModules.beta
    ];

    myHome = {
        packages.enable = true;
        hyprland = {
          enable = true;
          monitors = [
            "desc:BNQ BenQ GL2450 R4E01733019,preferred,0x0,1"
            "desc:BNQ BenQ GL2450H S5D02889019,preferred,-1920x0,1"
          ];
        };
      };
  };
}
