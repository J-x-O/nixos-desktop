{ pkgs, ... }:
{
  imports = [
    ../common.nix
    ./disko.nix
    ./hardware-configuration.nix
  ];
  networking.hostName = "tower";
  
  myHome = {
    hyprland = {
      monitors = [
        "desc:BNQ BenQ GL2450 R4E01733019,preferred,0x0,1"
        "desc:BNQ BenQ GL2450H S5D02889019,preferred,-1920x0,1"
      ];
    };
  };
  
  # we mount the other hard drive under /storage, so we should make it availiable to jesco
  systemd.tmpfiles.rules = [
    "z /storage 0775 jesco users -"
  ];
}
