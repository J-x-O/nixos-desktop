{ config, lib, pkgs, ... }: {
  options.myHome.wine.enable = lib.mkEnableOption "Wine with Unity game compatibility" // { default = true; };

  config = lib.mkIf config.myHome.wine.enable {
    environment.systemPackages = with pkgs; [
      wineWow64Packages.stagingFull
      winetricks
      dxvk
      vkd3d-proton
    ];
  };
}
