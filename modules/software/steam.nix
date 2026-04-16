{ config, lib, pkgs, ... }: {
  options.myHome.gaming.enable = lib.mkEnableOption "shared packages" // { default = false; };

  config = lib.mkIf config.myHome.gaming.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
      gamescopeSession.enable = true;
    };

  };
}
