{ ... }: {
  imports = [
      ../modules/software
      ../modules/common.nix
      ../modules/home.nix
      ../modules/security.nix
      ../modules/session.nix
      ../modules/focus.nix
    ];

  # we are using efi, so nodev because internet said so yes
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev";

  home-manager.backupFileExtension = "backup";

  # comment out the craft apps you don't want (see modules/software/craft)
  myHome.craft.apps = [
    "photocraft"   # image editor
    "vectorcraft"  # vector graphics
    "filmcraft"    # video editor
    "lightcraft"   # photo library / raw developer
    "pdfcraft"     # pdf editor
    "effectcraft"  # motion graphics
    "designcraft"  # layout / publishing
    "wordcraft"    # word processor
    "soundcraft"   # daw
    "deckcraft"    # presentations
    "gridcraft"    # spreadsheets
    "solidcraft"   # parametric 3d cad
  ];
}
