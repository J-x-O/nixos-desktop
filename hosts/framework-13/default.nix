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
        { output = "desc:AOC 24B31H AUYR39A004844"; position = "-3840x0"; }
        { output = "desc:AOC 24B31H AUYR39A004842"; position = "-1920x0"; }
        { output = "eDP-1"; position = "0x0"; scale = 1.666667; }
      ];
    };
  };
}
