#shared gui apps
{ vars, inputs, pkgs, lib, config, ... }: {
  options.myHome.packages.enable = lib.mkEnableOption "shared packages" // { default = true; };

  config = lib.mkIf config.myHome.packages.enable {
    # virtualisation.docker.enable = true;
    # users.users.${vars.username}.extraGroups = [ "docker" ];

    home-manager.users.${vars.username} = {
      home.packages = with pkgs; [
        # Creative & Media
        bitwig-studio
        blender
        inkscape
        scribus
        obs-studio
        kicad
        prusa-slicer
        upscayl
        vlc
        davinci-resolve

        # IDEs & Dev Tools
        vscode
        zed-editor
        unityhub
        godot-mono
        sourcegit
        ttyper
        nodejs   # JS runtime (vite, tsx, npm)
        bun      # package manager for bun.lock projects
        claude-code  # `claude` in the terminal, shares ~/.claude + ~/.claude.json (craft mcp servers) with zed's agent

        # Music / Audio Production
        decent-sampler          # might need custom derivation

        # Communication
        discord
        spotify

        # Office & Productivity
        loupe #image viewer
        kdePackages.kate #quick edit files
        kdePackages.ark
        unrar #rar backend for ark
        kdePackages.filelight
        kdePackages.kcalc
      ];
    };
  };
}
