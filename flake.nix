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

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-core, 
                     homebrew-cask, home-manager }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ ];

      environment.pathsToLink = [ "/share/zsh" ];

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";
      system.primaryUser = "samosaara";
      users.users.samosaara.home = /Users/samosaara;
      users.users.samosaara.shell = pkgs.fish;

      # Enable alternative shell support in nix-darwin.
      programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

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

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;

      home-manager.users.samosaara = {
          home.stateVersion = "25.05";
          home.username = "samosaara";

          home.shell.enableFishIntegration = true;
          home.packages = [
            pkgs.ffmpeg
            pkgs.vim
            pkgs.curl
            pkgs.heroku
            pkgs.fortune
            pkgs.cowsay
            pkgs.maven
            pkgs.httpie
            pkgs.bun
            pkgs.nodejs
            pkgs.nodePackages."@angular/cli"
            pkgs.pnpm
            pkgs.lolcat
            pkgs.sl
            pkgs.mise
          ];

          fonts.fontconfig.enable = false;

          programs.fish.enable = true;
          programs.fish.functions = {
            fish_greeting = "fortune | cowsay";
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
