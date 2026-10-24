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
    let
      mkFlake =
        args: module:
        assert inputs.nixpkgs.lib.assertMsg (args ? moduleLocation)
          "mkFlake: moduleLocation must be explicitly specified, such as `moduleLocation = ./flake.nix;` or `moduleLocation = __curPos.file;`.";
        inputs.flake-parts.lib.mkFlake args {
          imports = [
            inputs.flake-parts.flakeModules.modules
            inputs.treefmt-nix.flakeModule
            ./modules/fp/treefmt
            module
          ];
        };
    in
    mkFlake
      {
        inherit inputs;
        moduleLocation = __curPos.file;
        specialArgs =
          let
            lib = inputs.nixpkgs.lib;
          in
          {
            llib =
              let
                llib_ = import ./lib { inherit lib; };
              in
              llib_.mergeAttrsRecursive { allowOverrides = false; } [
                llib_
                { inherit mkFlake; }
              ];
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
                inputs',
                config,
                pkgs,
                lib,
                ...
              }:
              {
                checks = import ./tests {
                  inherit llib pkgs;
                  lib = pkgs.lib;
                };

                treefmt = {
                  flakeCheck = true;
                  settings.excludes = [
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
