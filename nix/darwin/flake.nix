{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, ... }:
    let
      configuration = { pkgs, config, ... }: {
        nixpkgs.config.allowUnfree = true;

        environment.systemPackages = [
          pkgs.neovim
          pkgs.mkalias
          pkgs.obsidian
	  pkgs.aldente
	  pkgs.rectangle
	  pkgs.warp-terminal
	  pkgs.spotify
	  pkgs.mpv
	  pkgs.discord
	  pkgs.appcleaner
	  pkgs.vscode
	  pkgs.git
        ];

	homebrew = {
	  enable = true;
	  brews = [
	    "mas"
	  ];
	  casks = [
	    "firefox"
	    "the-unarchiver"
	    "microsoft-teams"
	  ];
	  masApps = {
	    "Word" = 462054704;
	    "Sleep Control Center" = 946798523;
	    "Whatsapp" = 310633997;
	  };
	  onActivation.cleanup = "zap";
	};

        nix.settings.experimental-features = "nix-command flakes";
        programs.zsh.enable = true;
        system.configurationRevision = self.rev or self.dirtyRev or null;
        system.stateVersion = 5;
        nixpkgs.hostPlatform = "aarch64-darwin";

        # Agrega activationScripts correctamente
        system.activationScripts.applications.text = let
          env = pkgs.buildEnv {
            name = "system-applications";
            paths = config.environment.systemPackages;
            pathsToLink = "/Applications";
          };
        in
          pkgs.lib.mkForce ''
            # Set up applications.
            echo "setting up /Applications..." >&2
            rm -rf /Applications/Nix\ Apps
            mkdir -p /Applications/Nix\ Apps
            find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
            while read -r src; do
              app_name=$(basename "$src")
              echo "copying $src" >&2
              ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
            done
          '';
      };
    in
    {
      darwinConfigurations."dev" = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };

      darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
        modules = [
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "coffee";
              autoMigrate = true;
            };
          }
        ];
      };
    };

}

