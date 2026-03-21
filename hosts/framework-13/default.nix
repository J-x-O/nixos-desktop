{ pkgs, ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./home.nix
  ];
  _module.args.disk-target = "/dev/nvme0n1";
  networking.hostName = "framework-13";

  # we are using efi, so nodev because internet said so yes
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev";
}
