{ pkgs, ... }:
let
  photogimp = pkgs.fetchFromGitHub {
    owner = "Diolinux";
    repo = "PhotoGIMP";
    rev = "master";
    sha256 = "0kafb35s48723i8ywshfn3aq5kp7w9vnq8hl40n31vkynj4qwjjq";
  };
in {
  home.packages = [ pkgs.gimp ];

  home.file.".config/GIMP/3.0" = {
    source = "${photogimp}/.var/app/org.gimp.GIMP/config/GIMP/3.0";
    recursive = true;
  };
  home.file.".local/share/GIMP/3.0" = {
    source = "${photogimp}/.var/app/org.gimp.GIMP/data/GIMP/3.0";
    recursive = true;
  };
}