{ pkgs, ... }: {
  imports = [
    ./security.nix
    ./session.nix
  ];
  system.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;

  users.users.jesco = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    hashedPassword = "$6$A8/25/b1pmRdkXMi$JcVQT.AV9hUO4qI593qP6PihBQczowmk12.9XQHo/O39lvx/1peXzjmsmaMtAU7tQXb4juLKf1ureC.9Vs1Zw1";
    shell = pkgs.fish;
  };
  programs.fish.enable = true;

  networking.networkmanager.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
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
    vim
    git
  ];

  # germansky
  console.keyMap = "de";
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };
  services.xserver = {
    xkb.layout = "de";
    xkb.variant = "nodeadkeys";
  };
}
