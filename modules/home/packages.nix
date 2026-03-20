#shared gui apps
{ inputs, pkgs, lib, config, ... }: {
  options.myHome.packages.enable = lib.mkEnableOption "shared packages";

  config = lib.mkIf config.myHome.packages.enable {
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
      sourcegit

      # Music / Audio Production
      decent-sampler          # might need custom derivation

      # Communication
      discord
      protonmail-desktop
      zoom-us
      thunderbird
      spotify
      kdePackages.kdeconnect-kde

      # fileexplorer
      kdePackages.dolphin
      kdePackages.qtsvg
      kdePackages.kio # needed since 25.11
      kdePackages.kio-fuse #to mount remote filesystems via FUSE
      kdePackages.kio-extras #extra protocols support (sftp, fish and more)

      # Office & Productivity
      libreoffice-fresh
      kdePackages.okular #pdf
      loupe #image viewer
      kdePackages.kate #quick edit files
      kdePackages.ark
      kdePackages.filelight
      kdePackages.kcalc
    ];

    programs.zen-browser = {
      enable = true;
      setAsDefaultBrowser = true;
    };
  };
}
