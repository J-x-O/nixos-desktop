{ vars, ... }: {
  home-manager.users.${vars.username} = {
    home.file.".ssh/config".text = ''
      Host *
        IdentityFile ~/.ssh/github
        AddKeysToAgent yes
    '';

    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "Jesco";
          email = "JescoVogt@web.de";
        };
        init.defaultBranch = "main";
      };
    };

    services.gnome-keyring = {
      enable = true;
      components = [ "ssh" "secrets" "pkcs11" ];
    };

    programs.fish.enable = true;

    home.stateVersion = "25.11";
  };
}
