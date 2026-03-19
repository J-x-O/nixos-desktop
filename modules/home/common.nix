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

  programs.fish.enable = true;

  home.stateVersion = "25.11";
}
