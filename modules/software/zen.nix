{ inputs, vars, lib, ... }:
let
  extension = shortId: guid: {
    name = guid;
    value = {
      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
      installation_mode = "normal_installed";
    };
  };

  prefs = {
    "middlemouse.paste" = false;
    "zen.view.experimental-no-window-controls" = true;
    # DNS-over-HTTPS off so the browser resolves through the system (and /etc/hosts blocklist)
    "network.trr.mode" = 5;
  };

  extensions = [
    # To add additional extensions, find it on addons.mozilla.org, find
    # the short ID in the url (like https://addons.mozilla.org/en-US/firefox/addon/!SHORT_ID!/)
    # Then go to https://addons.mozilla.org/api/v5/addons/addon/!SHORT_ID!/ to get the guid
    #(extension "ublock-origin" "uBlock0@raymondhill.net")
  ];
in {
  # no official zen package/flake exists (nixpkgs PR still open), 0xc000022070's flake is the community standard
  # binary: zen-beta, desktop entry: zen-beta.desktop
  home-manager.users.${vars.username} = {
    imports = [ inputs.zen-browser.homeModules.beta ];

    programs.zen-browser = {
      enable = true;
      policies = {
        DisableTelemetry = true;
        DisableAppUpdate = true;
        Preferences = lib.mapAttrs (_: value: { Value = value; Status = "locked"; }) prefs;
        # ExtensionSettings = builtins.listToAttrs extensions;
      };
    };
  };
}
