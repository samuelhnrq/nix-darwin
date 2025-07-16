# vim: shiftwidth=2 tabstop=4
{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      home-manager,
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.gitFull
            pkgs.nixfmt-rfc-style
          ];

          environment.pathsToLink = [ "/share/zsh" ];

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";
          system.primaryUser = "samosaara";
          fonts.packages = [
            pkgs.nerd-fonts.fira-code
            pkgs.nerd-fonts.blex-mono
          ];
          users.users.samosaara = {
            home = /Users/samosaara;
          };
          environment.shells = [ "${pkgs.fish}/bin/fish" ];

          services.ipfs = {
            enable = true;
            enableGarbageCollection = true;
            package = pkgs.kubo.overrideAttrs (old: {
              src = pkgs.fetchurl {
                url = "https://github.com/ipfs/kubo/releases/download/${old.rev}/kubo-source.tar.gz";
                # invasive workaround, should be fixed upstream soon and I can remove this package override
                hash = "sha256-OubXaa2JWbEaakDV6pExm5PkiZ5XPd9uG+S4KwWb0xQ=";
              };
            });
          };

          programs.fish.enable = true;
          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;
          environment.extraInit = ''
            export SSH_AUTH_SOCK='/Users/samosaara/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock';
          '';

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          homebrew.enable = true;

          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "samosaara";

            # Optional: Declarative tap management
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };

            # Optional: Enable fully-declarative tap management
            #
            # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
            mutableTaps = false;
          };
          homebrew.casks = [
            "1password"
            "ghostty"
            "zen"
            "ungoogled-chromium"
            "slack"
            "orbstack"
            "jetbrains-toolbox"
            "visual-studio-code"
            "postman"
          ];
          homebrew.global.brewfile = true;
          homebrew.global.autoUpdate = false;
          homebrew.onActivation.autoUpdate = true;
          homebrew.onActivation.upgrade = true;

          home-manager.backupFileExtension = ".bak";
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.samosaara = {
            home.stateVersion = "25.05";
            home.username = "samosaara";

            home.shell.enableFishIntegration = true;
            home.packages = [
              # CLIs utils
              pkgs.ffmpeg
              pkgs.curl
              pkgs.httpie
              # Coding stuff
              pkgs.maven
              pkgs.bun
              pkgs.nixfmt-rfc-style
              # lols
              pkgs.lolcat
              pkgs.fortune
              pkgs.cowsay
              pkgs.sl
              # Infra
              pkgs.heroku
              pkgs.postgresql_15
              pkgs.flyway
            ];

            fonts.fontconfig.enable = false;

            programs.fish.enable = true;
            programs.fish.functions = {
              fish_greeting = "fortune | cowsay";
            };
            home.sessionVariables = {
              SSH_AUTH_SOCK = "/Users/samosaara/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
            };

            programs.mise = {
              enable = true;
              enableFishIntegration = true;
              enableZshIntegration = true;
              globalConfig = {
                tools = {
                  node = "24";
                  pnpm = "10";
                  yarn = "4";
                  "npm:jscodeshift" = "17";
                };
              };
            };

            programs.beets = {
              enable = true;
              package = (
                pkgs.beets.override {
                  pluginOverrides = {
                    lyrics.enable = true;
                    embedart.enable = true;
                    fetchart.enable = true;
                    fish.enable = true;
                    convert.enable = true;
                    replaygain.enable = true;
                  };
                }
              );
            };

            programs.neovim = {
              enable = true;
              defaultEditor = true;
              viAlias = true;
              vimAlias = true;
              extraConfig = ''
                set tabstop=4 shiftwidth=4 expandtab number relativenumber smartindent autoindent
              '';
            };

            programs.ghostty = {
              enable = true;
              package = pkgs.ghostty-bin;
              enableFishIntegration = true;
              enableZshIntegration = true;
              settings = {
                command = "${pkgs.fish}/bin/fish";
              };
            };

            programs.git = {
              enable = true;
              package = pkgs.gitFull;
              userEmail = "samosaara" + "@gmail.com";
              userName = "Samuel da Silva";
            };
          };
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#PivotHyrule
      darwinConfigurations."PivotHyrule" = nix-darwin.lib.darwinSystem {
        modules = [
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          configuration
        ];
      };
    };
}
