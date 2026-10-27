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
    local-nixpkgs = {
      url = "path:./pkgs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
  };

  outputs =
    { self, ... }@inputs:
    inputs.local-nixpkgs.lib.mkFlake inputs.nixpkgs
      ({ lib }: {
        inherit inputs;
        moduleLocation = __curPos.file;
        llib = inputs.local-nixpkgs.lib;
        lpkgs = inputs.local-nixpkgs;
      })
      (
        {
          llib,
          lpkgs,
          config,
          lib,
          ...
        }:
        {
          config = {
            systems = inputs.nixpkgs.lib.systems.flakeExposed;

            flake = {
              lib = {
                inherit (llib)
                  mkFlake
                  mergeAttrsRecursive
                  packages
                  tests
                  ;
              };
            };

            perSystem =
              {
                system,
                config,
                pkgs,
                lib,
                ...
              }:
              {
                legacyPackages = lpkgs.legacyPackages.${system};

                checks = import ./tests {
                  inherit llib;
                  pkgs = import inputs.nixpkgs { inherit system; };
                  lib = pkgs.lib;
                  nixFlakePatched = {
                    package = pkgs.nix-flake-patched;
                    legacyPackage = lpkgs.legacyPackages.${system}.nix-flake-patched;
                    defaultNix = pkgs.nix;
                  };
                };

                treefmt = {
                  flakeCheck = true;
                  settings.excludes = [
                    "*.patch"
                    ".gitignore"
                    "LICENSE"
                    "README.org"
                    "flake.lock"
                  ];
                };
              };
          };
        }
      );
}
