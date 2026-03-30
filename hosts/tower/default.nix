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

  # we mount the other hard drive under /storage, so we should make it availiable to jesco
  systemd.tmpfiles.rules = [
    "z /storage 0775 jesco users -"
  ];
}
