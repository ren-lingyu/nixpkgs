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
            overlayTree = import ./lib/overlay-tree.nix { inherit lib; };
            llib = import ./lib { inherit lib; };
          };
      }
      (
        {
          llib,
          overlayTree,
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
                checks = import ./tests {
                  inherit llib pkgs overlayTree;
                  lib = pkgs.lib;
                };

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
