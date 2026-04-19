{ vars, pkgs, ... }: {

  system.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  users.users.${vars.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    hashedPassword = "$6$A8/25/b1pmRdkXMi$JcVQT.AV9hUO4qI593qP6PihBQczowmk12.9XQHo/O39lvx/1peXzjmsmaMtAU7tQXb4juLKf1ureC.9Vs1Zw1";
    shell = pkgs.fish;
  };
  programs.fish.enable = true;

  networking.networkmanager.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;
  services.pipewire.wireplumber.extraConfig."10-bluez" = {
    "monitor.bluez.properties" = {
      "bluez5.enable-sbc-xq" = true;
      "bluez5.enable-msbc" = false;
      "bluez5.enable-hw-volume" = true;
      "bluez5.hfphsp-backend" = "native";
      "bluez5.roles" = [ "a2dp_sink" "a2dp_source" "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" ];
      "bluez5.dummy-avrcp-player" = true;
    };
  };
  services.pipewire.wireplumber.extraConfig."11-bluetooth-policy" = {
    "wireplumber.settings" = {
      "bluetooth.autoswitch-to-headset-profile" = true;
    };
  };

  # XDG Portal for screen sharing, file pickers, etc.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
    config.hyprland.default = [ "hyprland" "gtk" ];
  };
  programs.dconf.enable = true;

  programs.git = {
      enable = true;
  };

  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    fastfetch
  ];

  # germansky
  console.keyMap = "de";
  time.timeZone = "Europe/Berlin";

  services.xserver = {
    xkb.layout = "de";
    xkb.variant = "nodeadkeys";
  };
}
