{ ... }: {
  imports = [
    ./packages.nix
    ./hyprland.nix
    ./gimp.nix
  ];

  programs.git = {
    enable = true;
    settings.user = {
      name = "Jesco";
      email = "JescoVogt@web.de";
    };
  };
  
  services.gnome-keyring = {
    enable = true;
    components = [ "ssh" "secrets" "pkcs11" ];
  };

  programs.fish.enable = true;

  home.stateVersion = "25.11";
}
