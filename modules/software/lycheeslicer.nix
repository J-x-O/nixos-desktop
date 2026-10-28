{ vars, inputs, pkgs, lib, config, ... }: {
  options.myHome.lycheeslicer.enable = lib.mkEnableOption "lychee slicer" // { default = true; };

  config = lib.mkIf config.myHome.lycheeslicer.enable {
    # virtualisation.docker.enable = true;
    # users.users.${vars.username}.extraGroups = [ "docker" ];

    programs.kdeconnect.enable = true;

    # printer discovery: replies to the M99999 broadcast come from udp/3000 and aren't seen as conntrack replies
    networking.firewall = {
      allowedUDPPorts = [ 8000 ]; # fixed discovery listener port
      extraCommands = ''
        iptables -A nixos-fw -p udp --sport 3000 -j nixos-fw-accept
      '';
      extraStopCommands = ''
        iptables -D nixos-fw -p udp --sport 3000 -j nixos-fw-accept || true
      '';
    };

    home-manager.users.${vars.username} = {
      home.packages = with pkgs; [
        lycheeslicer
      ];

      # overrides nixpkgs' "Lychee Slicer.desktop" (same name) to add the lycheeslicer:// handler for the browser login callback
      xdg.desktopEntries."Lychee Slicer" = {
        name = "LycheeSlicer";
        genericName = "Resin Slicer";
        exec = "${pkgs.lycheeslicer}/bin/lycheeslicer %U";
        icon = "lycheeslicer";
        comment = "All-in-one 3D slicer for Resin and Filament";
        categories = [ "Graphics" ];
        mimeType = [ "x-scheme-handler/lycheeslicer" "model/stl" ];
        settings.StartupWMClass = "LycheeSlicer";
      };

      xdg.mimeApps.defaultApplications."x-scheme-handler/lycheeslicer" = [ "Lychee Slicer.desktop" ];
    };
  };
}
