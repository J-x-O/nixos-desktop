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
  };

  # XDG Portal for screen sharing, file pickers, etc.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  programs.git = {
      enable = true;
  };

  environment.systemPackages = with pkgs; [
    wget
    curl
    git
  ];

  # germansky
  console.keyMap = "de";
  time.timeZone = "Europe/Berlin";

  services.xserver = {
    xkb.layout = "de";
    xkb.variant = "nodeadkeys";
  };
}
