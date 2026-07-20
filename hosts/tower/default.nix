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
        { output = "desc:BNQ BenQ GL2450 R4E01733019"; position = "0x0"; }
        { output = "desc:BNQ BenQ GL2450H S5D02889019"; position = "-1920x0"; }
      ];
    };
    gaming.enable = true;
  };
  
  # we mount the other hard drive under /storage, so we should make it availiable to jesco
  systemd.tmpfiles.rules = [
    "z /storage 0775 jesco users -"
  ];
}
