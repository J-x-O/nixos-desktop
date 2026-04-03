{ vars, pkgs, lib, config, ... }: {

  options.myHome.dolphin.enable = lib.mkEnableOption "shared packages" // { default = true; };

  config = lib.mkIf config.myHome.dolphin.enable {
    environment.systemPackages = with pkgs; [
      ntfs3g # used for mounting NTFS drivesp
      kdePackages.kio-fuse #to mount remote filesystems via FUSE
      kdePackages.qtsvg
      kdePackages.kio # needed since 25.11
      kdePackages.kio-extras #extra protocols support (sftp, fish and more)
    ];
    home-manager.users.${vars.username} = {
      home.packages = with pkgs; [
        kdePackages.dolphin
      ];
    };
  };
}
