{ pkgs, vars, ... }: {
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time -r --cmd start-hyprland";
        user = "greeter";
      };
    };
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for many games/Steam
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Required services for illogical-impulse
  services.geoclue2.enable = true;  # For QtPositioning
  networking.networkmanager.enable = true;  # For network management
  services.upower.enable = true; # For battery status
  services.udisks2.enable = true; # used by illogical impulse

  # System fonts (optional but recommended)
  fonts.packages = with pkgs; [
    rubik
    nerd-fonts.ubuntu
    nerd-fonts.jetbrains-mono
  ];

}
