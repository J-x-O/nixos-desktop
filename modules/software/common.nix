#shared gui apps
{ vars, inputs, pkgs, lib, config, ... }: {
  options.myHome.packages.enable = lib.mkEnableOption "shared packages" // { default = true; };

  config = lib.mkIf config.myHome.packages.enable {
    virtualisation.docker.enable = true;
    users.users.${vars.username}.extraGroups = [ "docker" ];

    programs.kdeconnect.enable = true;

    home-manager.users.${vars.username} = {
      home.packages = with pkgs; [
        # Creative & Media
        bitwig-studio
        blender
        inkscape
        obs-studio
        freecad
        kicad
        prusa-slicer
        upscayl
        vlc

        # IDEs & Dev Tools
        vscode
        zed-editor
        jetbrains.pycharm
        jetbrains.rider
        jetbrains.rust-rover
        jetbrains.webstorm
        unityhub
        godot-mono
        sourcegit
        ttyper

        # Music / Audio Production
        decent-sampler          # might need custom derivation

        # Communication
        discord
        spotify

        # Office & Productivity
        libreoffice-fresh
        loupe #image viewer
        kdePackages.kate #quick edit files
        kdePackages.ark
        kdePackages.filelight
        kdePackages.kcalc
      ];
    };
  };
}
