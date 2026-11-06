{ inputs, ... }: {
  # Keep Godot frozen at its pinned nixpkgs rev (see flake.nix) so system
  # updates don't push a new editor version onto the team.
  nixpkgs.overlays = [
    # The pinned build links an older glibc than the system Mesa/.NET, so it
    # can't load /run/opengl-driver or the global DOTNET_ROOT (crashes in
    # EGLManager). Wrap it to use Mesa and dotnet from its own pinned nixpkgs.
    (final: prev:
      let
        pinned = import inputs.nixpkgs-godot {
          inherit (prev.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        };
        mesa = pinned.mesa;
      in {
        godot-mono = prev.symlinkJoin {
          name = "godot-mono-pinned-${pinned.godot-mono.version}";
          paths = [ pinned.godot-mono ];
          nativeBuildInputs = [ prev.makeWrapper ];
          postBuild = ''
            for f in $out/bin/*; do
              wrapProgram "$f" \
                --unset DOTNET_ROOT \
                --prefix LD_LIBRARY_PATH : ${mesa}/lib \
                --set VK_DRIVER_FILES ${mesa}/share/vulkan/icd.d/intel_icd.x86_64.json \
                --set __EGL_VENDOR_LIBRARY_FILENAMES ${mesa}/share/glvnd/egl_vendor.d/50_mesa.json \
                --set GBM_BACKENDS_PATH ${mesa}/lib/gbm \
                --set LIBGL_DRIVERS_PATH ${mesa}/lib/dri
            done
            for d in $out/share/applications/*.desktop; do
              cp --remove-destination "$(readlink -f "$d")" "$d"
              substituteInPlace "$d" --replace-fail ${pinned.godot-mono} $out
            done
          '';
        };
      })
  ];
}
