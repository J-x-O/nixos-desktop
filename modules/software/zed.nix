{ vars, pkgs, lib, config, ... }:
{
  options.myHome.zed.enable = lib.mkEnableOption "shared packages" // { default = true; };
  config = lib.mkIf config.myHome.zed.enable {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc.lib zlib openssl icu
    ];
    environment.systemPackages = with pkgs; [
      dotnet-sdk_10
    ];
    environment.variables.DOTNET_ROOT = "${pkgs.dotnet-sdk_10}/share/dotnet";

    home-manager.users.${vars.username} = { lib, ... }: {
      programs.zed-editor = {
        enable = true;
        userSettings = {
          theme = {
            mode = "dark";
            dark = "Ayu Mirage";
            light = "Ayu Light";
          };
          hour_format = "hour24";
          vim_mode = true;
        };
        userKeymaps = [
          {
            context = "Editor && vim_mode == normal";
            bindings = {
              "space f" = "file_finder::Toggle";
              "space s" = "workspace::ActivatePaneLeft";
              "space b" = "pane::GoBack";
              "space e" = "editor::GoToDefinition";
              "space /" = "workspace::NewSearch";
              "space w" = "workspace::Save";
              "space g" = "workspace::ActivatePaneLeft";
              "space r n" = "editor::Rename";
              "space o" = "editor::ToggleCodeActions";
              "space q" = "pane::CloseActiveItem";
            };
          }
          {
            context = "Editor && vim_mode == visual";
            bindings = {
              "space /" = "workspace::NewSearch";
            };
          }
        ];
      };
    };
  };
}