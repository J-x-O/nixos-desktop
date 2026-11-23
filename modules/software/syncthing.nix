# Syncthing: keeps ~/Sync identical on every machine, with the home server as the always-on node.
# This machine's device ID is generated on first start; approve it once in the server's web UI
# (https://sync.home.jesco.dev) and share the `sync` folder with it.
{ vars, ... }: {
  services.syncthing = {
    enable = true;
    user = vars.username;
    dataDir = vars.homeDirectory;
    configDir = "${vars.homeDirectory}/.config/syncthing";
    openDefaultPorts = true;

    settings = {
      devices.homeserver = {
        id = "WITCNIK-LYJUUXI-VLAMCMN-UCIV7I7-Z7FZ3Z3-UC7P7WZ-LVA76X4-ZOW53AA";
        # LAN first, then wherever discovery finds it (Tailscale route when away).
        addresses = [ "tcp://192.168.178.40:22000" "dynamic" ];
        autoAcceptFolders = true;
      };

      folders.sync = {
        path = "${vars.homeDirectory}/Sync";
        id = "sync";
        devices = [ "homeserver" ];
      };
    };
  };
}
