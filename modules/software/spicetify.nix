# Re-themes Spotify automatically whenever kde-material-you-colors regenerates
# colors (i.e. on every wallpaper/color change), the same way Dolphin/Konsole/
# kitty/GTK already do via the illogical-impulse + matugen + kde-material-you-colors
# pipeline. No manual `spicetify apply` or rebuild needed per color change.
#
# Spotify itself lives in the read-only /nix/store, but spicetify needs to patch
# its files in place, so we keep a writable copy and point a launcher at it.
{ vars, pkgs, lib, config, ... }:

let
  # luisbocanegra/spicetify-kde-material-you: ships a spicetify theme plus
  # material-you-spicetify.py, designed to run as kde-material-you-colors'
  # on_change_hook and translate its palette into spicetify's color.ini.
  materialYouTheme = pkgs.fetchFromGitHub {
    owner = "luisbocanegra";
    repo = "spicetify-kde-material-you";
    rev = "ab9c65a2fe123efda94855df3fbeaa8d32e8d9f6";
    hash = "sha256-JZZkbn3Kkmr7mMCTWpGEi4HPO0UbbrJzOPNrlR4LaNA=";
  };

  spotifyWritableDir = "${vars.homeDirectory}/.local/share/spicetify-spotify";
  hookScriptPath = "${vars.homeDirectory}/.config/spicetify/material-you-spicetify.py";
  onColorChangeScriptPath = "${vars.homeDirectory}/.config/spicetify/on-color-change.sh";
  reloadScriptPath = "${vars.homeDirectory}/.config/spicetify/reload-live.mjs";

  # Empirically, once `spicetify enable-devtools` has patched Spotify's offline.bnk,
  # the client's remote-debugging endpoint consistently comes up on port 8088 (not the
  # 9222 spicetify's own `watch` command passes as a launch flag -- we never pass that
  # flag ourselves, so this is whatever Spotify's own developer-mode default is). Verified
  # stable across many relaunches while developing this. If it ever stops matching, the
  # reload script below just silently no-ops (fetch fails), so this isn't a hard dependency.
  spotifyDevtoolsPort = 8088;

  # nixpkgs' spicetify-cli package only `cp -r`s the repo's checked-in jsHelper/ dir
  # (see pkgs/by-name/sp/spicetify-cli/package.nix), but jsHelper/spicetifyWrapper.js
  # is a build artifact (bundled from src/jsHelper/spicetifyWrapper/*.js via esbuild,
  # see package.json's "build:wrapper" script) that's never committed to git, so it's
  # missing from every nixpkgs build. Without it, `window.Spicetify` never gets defined
  # and xpui's injected helper scripts throw "Spicetify is not defined", crashing the
  # renderer before it ever paints -- Spotify opens to a blank window. Rebuild it
  # ourselves from spicetify-cli's own pinned source so it always matches the installed
  # spicetify-cli version.
  spicetifyWrapperJs = pkgs.runCommand "spicetify-wrapper.js" { } ''
    ${pkgs.esbuild}/bin/esbuild ${pkgs.spicetify-cli.src}/src/jsHelper/spicetifyWrapper/index.js \
      --bundle --format=iife --minify --target=chrome108 --legal-comments=none \
      --outfile=$out
  '';

  # nixpkgs' `spotify` wrapper sets up GIO_EXTRA_MODULES/XDG_DATA_DIRS/LD_LIBRARY_PATH/PATH
  # then execs the real binary from the store. Reuse that logic verbatim (so it stays in
  # sync with whatever nixpkgs' spotify derivation needs) but redirect the final exec to
  # our writable copy, since spicetify apply needs write access to the app directory.
  spotifyWrapper = pkgs.writeScriptBin "spotify" (
    builtins.replaceStrings
      [ "${pkgs.spotify}/share/spotify/.spotify-wrapped" ]
      [ "${spotifyWritableDir}/share/spotify/.spotify-wrapped" ]
      (builtins.readFile "${pkgs.spotify}/bin/spotify")
  );

  hyprlandEnabled = config.myHome.hyprland.enable;
in
{
  options.myHome.spicetify.enable = lib.mkEnableOption "spicetify auto re-theming for Spotify" // { default = true; };

  # home-manager.users.<user> is a function here (not a plain attrset) so that its own
  # `config`/`lib` (home-manager's module system) are in scope below -- needed for
  # `config.lib.dag`, which only exists inside home-manager's config, not NixOS's.
  config = lib.mkIf config.myHome.spicetify.enable {
    home-manager.users.${vars.username} = { config, lib, pkgs, ... }: {
      home.packages = [
        pkgs.spicetify-cli
        # Higher priority than the plain `spotify` package (still installed via
        # modules/software/common.nix for its desktop entry/icons/MIME handlers)
        # so this shadows just the `bin/spotify` file, not the whole package.
        (lib.hiPrio spotifyWrapper)
      ];

      # Copy nixpkgs' read-only Spotify install into a writable location so spicetify
      # can patch it in place. Runs on every activation; rsync only touches files that
      # actually changed, so a Spotify version bump in nixpkgs is picked up for free.
      home.activation.spicetifySpotifyCopy = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "${spotifyWritableDir}/share"
        $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -a --delete "${pkgs.spotify}/share/spotify/" "${spotifyWritableDir}/share/spotify/"
        $DRY_RUN_CMD chmod -R u+w "${spotifyWritableDir}"
      '';

      # Install the MaterialYou spicetify theme and its kde-material-you-colors hook script.
      home.activation.spicetifyTheme = config.lib.dag.entryAfter [ "spicetifySpotifyCopy" ] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.config/spicetify/Themes"
        if [ -e "$HOME/.config/spicetify/Themes/MaterialYou" ] || [ -L "$HOME/.config/spicetify/Themes/MaterialYou" ]; then
          $DRY_RUN_CMD rm -rf "$HOME/.config/spicetify/Themes/MaterialYou"
        fi
        $DRY_RUN_CMD cp -r "${materialYouTheme}/MaterialYou" "$HOME/.config/spicetify/Themes/MaterialYou"
        $DRY_RUN_CMD cp -f "${materialYouTheme}/material-you-spicetify.py" "${hookScriptPath}"
        $DRY_RUN_CMD chmod -R u+w "$HOME/.config/spicetify/Themes/MaterialYou" "${hookScriptPath}"
        # The copy above just reset color.ini to the theme's bundled default palette.
        # Immediately re-sync it from kde-material-you-colors' last-generated output
        # (rather than waiting for the next wallpaper/color change to fire on_change_hook),
        # so every rebuild reflects the current system colors instead of reverting them.
        $DRY_RUN_CMD ${pkgs.python3}/bin/python3 "${hookScriptPath}" || true

        # Reloads the active Spotify page in place via the Chrome DevTools Protocol --
        # re-parses colors.css from disk like a real page load, but keeps the same OS
        # process (no window destroy/recreate, no playback/tray/MPRIS interruption from
        # killing the process). Best-effort: if Spotify isn't running or devtools isn't
        # reachable, this silently no-ops -- colors.css is still correctly synced on disk
        # either way, so it'll just apply next time Spotify is opened normally.
        cat > "${reloadScriptPath}" << 'RELOADSCRIPTEOF'
try {
  const listResp = await fetch("http://127.0.0.1:${toString spotifyDevtoolsPort}/json/list");
  const targets = await listResp.json();
  const page = targets.find((t) => t.type === "page");
  if (!page) process.exit(0);

  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => {
    ws.addEventListener("open", resolve);
    ws.addEventListener("error", reject);
  });
  ws.send(JSON.stringify({ id: 1, method: "Page.reload", params: { ignoreCache: true } }));
  await new Promise((resolve) => setTimeout(resolve, 500));
  ws.close();
} catch {
  // Spotify not running / devtools not available -- nothing to do.
}
RELOADSCRIPTEOF

        # kde-material-you-colors' on_change_hook runs this on every wallpaper/color change.
        # material-you-spicetify.py only updates the *source* color.ini under
        # ~/.config/spicetify/Themes/MaterialYou/ -- `spicetify apply` bakes a static
        # colors.css into the writable Spotify copy once, so updating the source alone
        # never reaches an already-patched (or already-running) Spotify. `spicetify refresh
        # -s` regenerates that baked colors.css/user.css cheaply (no full re-patch), then
        # reload-live.mjs pushes it into the running window without restarting it. (Neither
        # `spicetify watch -s` nor `spicetify restart` proved reliable against this writable
        # copy in testing -- watch never detected file changes and spun at ~85% CPU, restart
        # silently no-op'd since it pgrep -x's for a process literally named "spotify", which
        # ours isn't -- so this reimplements the reload directly instead.)
        cat > "${onColorChangeScriptPath}" << 'ONCOLORCHANGEEOF'
#!/usr/bin/env bash
set -uo pipefail
${pkgs.python3}/bin/python3 "${hookScriptPath}"
${pkgs.spicetify-cli}/bin/spicetify refresh -s >/dev/null 2>&1
${pkgs.nodejs}/bin/node "${reloadScriptPath}" >/dev/null 2>&1
ONCOLORCHANGEEOF
        $DRY_RUN_CMD chmod u+x "${onColorChangeScriptPath}"
      '';

      # spicetify apply rewrites config-xpui.ini in place (fills in [Backup] version/hash),
      # so it must be a plain writable file, not a home-manager-managed store symlink.
      # Regenerated fresh every activation; spicetify's own [Backup] bookkeeping gets
      # re-derived immediately after by spicetifyApply below.
      home.activation.spicetifyConfig = config.lib.dag.entryAfter [ "spicetifyTheme" ] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.config/spicetify"
        cat > "$HOME/.config/spicetify/config-xpui.ini" << 'SPICETIFYCONFEOF'
[Setting]
inject_theme_js        = 1
inject_css             = 1
prefs_path              = ${vars.homeDirectory}/.config/spotify/prefs
current_theme           = MaterialYou
color_scheme            = auto
replace_colors          = 1
overwrite_assets        = 0
spotify_launch_flags    =
check_spicetify_update  = 0
always_enable_devtools  = 1
spotify_path            = ${spotifyWritableDir}/share/spotify

[Preprocesses]
disable_sentry     = 1
disable_ui_logging = 1
remove_rtl_rule    = 1
expose_apis        = 1

[AdditionalOptions]
extensions            =
custom_apps           =
sidebar_config        = 0
home_config           = 1
experimental_features = 1

[Patch]

; DO NOT CHANGE!
[Backup]
version =
with    =
SPICETIFYCONFEOF
      '';

      # Bootstrap/refresh the patch against the writable copy. `backup apply` (rather than
      # just `apply`) re-baselines every run, so it self-heals after a Spotify version bump
      # in nixpkgs. Tolerant of failure: Spotify may never have been launched yet on a fresh
      # account (no ~/.config/spotify/prefs), so don't fail the whole activation over it.
      home.activation.spicetifyApply = config.lib.dag.entryAfter [ "spicetifyConfig" ] ''
        $DRY_RUN_CMD ${pkgs.spicetify-cli}/bin/spicetify backup apply || true
        # Patches Spotify's own ~/.cache/spotify/offline.bnk to permanently enable its
        # remote-debugging endpoint, which on-color-change.sh needs to push live theme
        # reloads (see reload-live.mjs above). Requires Spotify to have been launched at
        # least once already (offline.bnk doesn't exist before that), so this is tolerant
        # of failure on a fresh install -- it'll just succeed on the next activation instead.
        $DRY_RUN_CMD ${pkgs.spicetify-cli}/bin/spicetify enable-devtools || true
        # Work around the missing jsHelper/spicetifyWrapper.js in nixpkgs' spicetify-cli
        # (see spicetifyWrapperJs above) -- must run after apply, since apply re-extracts
        # xpui.spa fresh every time and would otherwise wipe this out.
        helperDir="${spotifyWritableDir}/share/spotify/Apps/xpui/helper"
        if [ -d "$helperDir" ]; then
          $DRY_RUN_CMD cp -f "${spicetifyWrapperJs}" "$helperDir/spicetifyWrapper.js"
          $DRY_RUN_CMD chmod u+w "$helperDir/spicetifyWrapper.js"
        fi
      '';

      # Point kde-material-you-colors' on_change_hook at the theme's color-update script, so
      # Spotify re-themes on every wallpaper/color change like Dolphin/Konsole/kitty/GTK do.
      # Must run after illogical-flake's copyIllogicalImpulseConfigs, which overwrites
      # ~/.config/kde-material-you-colors/config.conf from its upstream dotfiles every activation.
      home.activation.spicetifyHook = config.lib.dag.entryAfter (
        [ "spicetifyTheme" ] ++ lib.optional hyprlandEnabled "copyIllogicalImpulseConfigs"
      ) ''
        confFile="$HOME/.config/kde-material-you-colors/config.conf"
        hookCmd="${onColorChangeScriptPath}"
        if [ -f "$confFile" ]; then
          if grep -q "^on_change_hook" "$confFile"; then
            $DRY_RUN_CMD sed -i "s|^on_change_hook.*|on_change_hook = $hookCmd|" "$confFile"
          else
            $DRY_RUN_CMD bash -c "printf '\non_change_hook = %s\n' \"$hookCmd\" >> \"$confFile\""
          fi
        fi
      '';
    };
  };
}
