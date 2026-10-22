{

  description = "Personal nixpkgs";

  inputs = {
    nixpkgs = {
      url = "git+https://github.com/NixOS/nixpkgs.git?ref=refs/heads/nixpkgs-unstable&shallow=1";
    };
    flake-parts = {
      url = "git+https://github.com/hercules-ci/flake-parts.git?ref=refs/heads/main&shallow=1";
    };
    treefmt-nix = {
      url = "git+https://github.com/numtide/treefmt-nix.git?ref=refs/heads/main&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, ... }@inputs:
    inputs.flake-parts.lib.mkFlake
      {
        inherit inputs;

        specialArgs =
          let
            lib = inputs.nixpkgs.lib;
          in
          rec {
            llib = import ./lib { inherit lib; };
          };
      }
      (
        {
          llib,
          config,
          lib,
          ...
        }:
        {
          imports = [ inputs.treefmt-nix.flakeModule ];

          config = {
            systems = inputs.nixpkgs.lib.systems.flakeExposed;

            flake = {
              lib = llib;
            };

            perSystem =
              {
                inputs',
                config,
                pkgs,
                lib,
                ...
              }:
              {
                checks = builtins.mapAttrs (
                  name_: results_:
                  builtins.seq results_ (pkgs.writeText "${name_}-tests.json" (builtins.toJSON results_))
                ) (import ./tests { inherit llib; });

                treefmt = {
                  flakeFormatter = true;
                  flakeCheck = true;
                  enableDefaultExcludes = false;
                  projectRootFile = builtins.baseNameOf __curPos.file;
                  settings.excludes = [
                    ".gitignore"
                    "LICENSE"
                    "README.org"
                    "flake.lock"
                  ];
                  programs = {
                    nixfmt = {
                      enable = true;
                      package = pkgs.nixfmt;
                      width = 100;
                      indent = 2;
                      strict = true;
                    };
                  };
                };
              };
          };
        }
      );
}
