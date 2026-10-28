{ vars, pkgs, lib, config, ... }:
let
  pname = "chitubox-basic";
  version = "2.3.1";

  # CHITUBOX ships Qt Installer Framework .run files that refuse to install without root.
  # Their components are plain 7z archives appended to the binary, so extract those directly instead.
  extractInstaller = { name, version, src, postInstall ? "" }: pkgs.stdenv.mkDerivation {
    pname = "${name}-unpacked";
    inherit version src postInstall;
    dontUnpack = true;

    nativeBuildInputs = with pkgs; [ _7zz python3 icoutils ];

    installPhase = ''
      runHook preInstall
      python3 -c '
      import sys, mmap
      f = open(sys.argv[1], "rb")
      m = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
      i = m.find(b"7z\xbc\xaf\x27\x1c")
      while i != -1:
          print(i)
          i = m.find(b"7z\xbc\xaf\x27\x1c", i + 1)
      ' $src | while read -r off; do
        tail -c +$((off + 1)) $src > component.7z
        7zz x -t7z -y -o$out/opt component.7z >/dev/null 2>&1 || echo "skipping non-component archive at $off"
      done
      rm -f component.7z
      runHook postInstall
    '';

    # bundles its own Qt; leave the binaries alone and run them in the FHS env
    dontAutoPatchelf = true;
    dontStrip = true;
    dontPatchELF = true;
  };

  unpacked = extractInstaller {
    name = pname;
    inherit version;
    src = pkgs.fetchurl {
      name = "${pname}-${version}.run";
      url = "https://sac.chitubox.com/software/download.do?installerUrl=https%3A%2F%2Fdownload.chitubox.com%2F17839%2Fv${version}%2FCHITUBOX_Basic_linux_Installer_${version}&softwareId=17839&softwareVersionId=v${version}";
      hash = "sha256-OX4FjeU7aS4dthZXkp4c6fiPCQy5c8jCD95bDU36Ymg=";
    };
    postInstall = ''
      # windows-only ffmpeg builds, ~330MB
      rm -f $out/opt/bin/Resources/DependentSoftware/recordOrShot/*.exe

      icotool --extract $out/opt/bin/Resources/Image/SoftwareIcon/freeIcon.ico --output .
      install -Dm644 freeIcon_1_256x256x32.png $out/share/icons/hicolor/256x256/apps/chitubox-basic.png
    '';
  };

  # printer management companion; CHITUBOX would otherwise download and install it at runtime.
  # URL from https://sac.chitubox.com/PCVersionUpdate/getInfo.do6?softwareType=17947&platform=4&majorVersion=0.0.1&silentVersion=0.0.0&login=0&customerMail=0
  chitumanager = extractInstaller {
    name = "chitumanager";
    version = "0.0.2";
    src = pkgs.fetchurl {
      name = "chitumanager-0.0.2.run";
      url = "https://download.chitubox.com/chitubox/chitubox/public/software/release/1/17947/0.0.2/4/2025-09-26/2836e09cc9de4c268081dcf004234a53.run";
      hash = "sha256-kR7bVjepxiVCsHWo9rtsLRsgLyQ1QWes+OyY1FgDqsg=";
    };
  };

  launcher = pkgs.writeShellScript "${pname}-launcher" ''
    data_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/${pname}"

    # sync <store opt dir> <target> <paths to copy for real...>: symlink tree, rebuilt when the store path changes
    sync() {
      src=$1 dst=$2; shift 2
      [ "$(cat "$dst/.source" 2>/dev/null)" = "$src" ] && return
      rm -rf "$dst"
      mkdir -p "$dst"
      cp -rs "$src/opt/." "$dst"
      chmod -R u+w "$dst"
      for f in "$@"; do
        rm -rf "$dst/$f"
        cp -rL "$src/opt/$f" "$dst/$f"
      done
      chmod -R u+w "$dst"
      echo "$src" > "$dst/.source"
    }

    sync ${unpacked} "$data_dir/app" CHITUBOX_Basic.sh bin/CHITUBOX_Basic bin/Resources/Conf
    sync ${chitumanager} "$data_dir/ChituManager" ChituManager.sh bin/ChituManager

    # both apps seed their user data by copying defaults out of the (read-only) store and keep the 0444 mode,
    # which breaks saving settings and adding printers (Printer.db)
    for d in chitubox2_0 chituboxResource ChituManager; do
      [ -d "''${XDG_DATA_HOME:-$HOME/.local/share}/$d" ] && chmod -R u+w "''${XDG_DATA_HOME:-$HOME/.local/share}/$d"
    done

    # CHITUBOX looks ChituManager up via this file and offers to download it when it's missing
    mkdir -p "$HOME/.ChituManager"
    echo "$data_dir/ChituManager" > "$HOME/.ChituManager/path"

    export QTWEBENGINE_DISABLE_SANDBOX=1
    unset QT_PLUGIN_PATH
    export QT_QPA_PLATFORMTHEME=xdgdesktopportal
    export QT_QPA_PLATFORM=xcb
    exec "$data_dir/app/CHITUBOX_Basic.sh" "$@"
  '';

  desktopItem = pkgs.makeDesktopItem {
    name = pname;
    desktopName = "CHITUBOX Basic";
    genericName = "Resin Slicer";
    exec = "${pname} %F";
    icon = pname;
    categories = [ "Graphics" "3DGraphics" ];
    mimeTypes = [ "model/stl" ];
  };

  chitubox = pkgs.buildFHSEnv {
    name = pname;
    targetPkgs = p: with p; [
      zlib bzip2 xz zstd dbus glib fontconfig freetype expat krb5 nspr nss
      gnutls numactl # ChituManager (libgnutls.so.30, libnuma.so.1)
      libGL libglvnd libdrm mesa libxkbcommon wayland
      libx11 libxcb libxext libxfixes libxshmfence
      libxrender libxi libxrandr libxcomposite libxdamage
      libxtst libxcursor libxcb-image libxcb-keysyms
      libxcb-render-util libxcb-wm libxcb-cursor libxkbfile
      gtk3 atk cairo pango gdk-pixbuf
      gst_all_1.gstreamer gst_all_1.gst-plugins-base
      alsa-lib cups libpulseaudio
      udev
      xkeyboard_config
    ];
    runScript = launcher;

    extraInstallCommands = ''
      install -Dm644 ${unpacked}/share/icons/hicolor/256x256/apps/chitubox-basic.png -t $out/share/icons/hicolor/256x256/apps
      install -Dm644 ${desktopItem}/share/applications/${pname}.desktop -t $out/share/applications
    '';
  };
in {
  options.myHome.chitubox.enable = lib.mkEnableOption "chitubox basic" // { default = true; };

  config = lib.mkIf config.myHome.chitubox.enable {
    home-manager.users.${vars.username} = {
      home.packages = [ chitubox ];
    };
  };
}
