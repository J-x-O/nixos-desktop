{ pkgs, ... }:
{
  imports = [
    ../common.nix
    ./disko.nix
    ./hardware-configuration.nix
  ];
  networking.hostName = "framework-13";

  myHome = {
      hyprland = {
        monitors = [
          "desc:AOC 24B31H AUYR39A004844,preferred,-3840x0,1,"
          "desc:AOC 24B31H AUYR39A004842,preferred,-1920x0,1"
          "eDP-1,preferred,0x0,1.666667,transform, 0"
        ];
      };
    };
}
