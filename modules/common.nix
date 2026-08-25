{ vars, pkgs, ... }: {

  system.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  users.users.${vars.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" "dialout"];
    hashedPassword = "$6$A8/25/b1pmRdkXMi$JcVQT.AV9hUO4qI593qP6PihBQczowmk12.9XQHo/O39lvx/1peXzjmsmaMtAU7tQXb4juLKf1ureC.9Vs1Zw1";
    shell = pkgs.fish;
  };
  programs.fish.enable = true;
  services.envfs.enable = true; # fix for some platformio stuff

  networking.networkmanager.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
      };
      Policy.AutoEnable = true;
    };
  };
  services.blueman.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # XDG Portal for screen sharing, file pickers, etc.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
    config.hyprland.default = [ "hyprland" "gtk" ];
  };
  programs.dconf.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      fuse3
      icu
      nss
      openssl
      curl
      expat
      libGL
      udev
      alsa-lib
      libx11
      libxcursor
      libxrandr
      libxi
    ];
  };

  programs.git = {
      enable = true;
  };

  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    fastfetch
    ghostscript
  ];

  # germansky
  console.keyMap = "de";
  time.timeZone = "Europe/Berlin";

  services.xserver = {
    xkb.layout = "de";
    xkb.variant = "nodeadkeys";
  };
}
