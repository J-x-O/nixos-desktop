{ pkgs, ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./home.nix
  ];
  networking.hostName = "tower";

  # we are using efi, so nodev because internet said so yes
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev";
}
