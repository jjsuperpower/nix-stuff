{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "jon";
  home.homeDirectory = "/home/jon";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    nixfmt
    nixd
    rust-analyzer
    rustfmt
    ruff
    lldb
  ];

  programs.opencode = {
    enable = true;

    settings.disabled_providers = [
      "open-web-ui"
      "opencode"
      "openai"
      "lmstudio"
      "lm-studio-l"
    ];

    settings.provider.biab = {
      name = "BIAB";
      npm = "@ai-sdk/openai-compatible";
      options.baseURL = "https://ai.us1.boxinaboxstudios.com/v1";
      models.auto.name = "Auto";
    };
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/jon/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "hx";
    PATH = "$PATH:~/.cargo/bin/";
  };

  # Global shell aliases that work across all shells
  home.shellAliases = {
    # You can add additional global aliases if needed
  };

  programs.git = {
    enable = true;
    settings.user.name = "jjsuperpower";
    settings.user.email = "jjs29356@gmail.com";
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      jon = {
        email = "jjs29356@gmail.com";
        name = "jjsuperpower";
      };
    };
  };

  programs.starship = {
    enable = true;
    # custom settings
    settings = {
      add_newline = false;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
    };
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      zyp = "zypper";
      sudo = "sudo ";
      tar-c = "tar -zcvf ";
      tar-e = "tar -zxvf ";
      ls = "eza";
      find = "fd";
    };
  };

  programs.zoxide.enable = true;

  programs.helix = {
    enable = true;
    settings = {
      keys.insert.j.k = "normal_mode";
      theme = "onedark";
    };
    languages.language = [
      {
        name = "nix";
        auto-format = true;
        formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
        language-servers = [ "nixd" ];
      }
      {
        name = "rust";
        auto-format = true;
        formatter.command = "${pkgs.rustfmt}/bin/rustfmt";
        language-servers = [ "rust-analyzer" ];
      }
      {
        name = "python";
        auto-format = true;
        formatter.command = "${pkgs.ruff}/bin/ruff";
        language-servers = [ "ruff" ];
      }
    ];
    languages.language-server = {
      nixd.command = "${pkgs.nixd}/bin/nixd";
      rust-analyzer.command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
      ruff.command = "${pkgs.ruff}/bin/ruff";
    };
  };

  programs.home-manager.enable = true;
}
