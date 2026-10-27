{
  description = "Personal nixpkgs";

  inputs = {
    nixpkgs = {
      url = "git+https://github.com/NixOS/nixpkgs.git?ref=refs/heads/nixpkgs-unstable&shallow=1";
    };
    local-nixpkgs = {
      url = "path:./pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
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

                packages = {
                  nix = pkgs.nix-flake-patched;
                };

                checks = import ./tests {
                  inherit llib;
                  pkgs = import inputs.nixpkgs { inherit system; };
                  lib = pkgs.lib;
                  nix-flake-patched = pkgs.nix-flake-patched;
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
