{
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
          lpkgs,
          config,
          lib,
          ...
        }@toplevel:
        {
          config = {
            systems = inputs.nixpkgs.lib.systems.flakeExposed;

            flake = {
              lib = llib.mergeAttrsRecursive { allowOverrides = false; } [
                llib
                {
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
                }
              ];
            };
          };
        }
      );
}
