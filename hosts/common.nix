{ ... }: {
  imports = [
      ../modules/software
      ../modules/common.nix
      ../modules/home.nix
      ../modules/security.nix
      ../modules/session.nix
    ];

  # we are using efi, so nodev because internet said so yes
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev";

  home-manager.backupFileExtension = "backup";
}
