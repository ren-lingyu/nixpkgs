{
  description = "Personal nixpkgs";

  inputs = {
    nixpkgs = {
      url = "git+https://github.com/NixOS/nixpkgs.git?ref=refs/heads/nixpkgs-unstable&shallow=1";
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      local-nixpkgs = builtins.getFlake ./pkgs;
    in
    local-nixpkgs.lib.mkFlake inputs.nixpkgs
      ({ lib }: {
        inherit inputs;
        moduleLocation = __curPos.file;
        llib = local-nixpkgs.lib;
        lpkgs = local-nixpkgs;
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
                nixpkgs.overlays = lib.mkForce [ lpkgs.overlays.legacy ];

                legacyPackages = pkgs.legacyPackages;

                packages = {
                  nix = pkgs.nix-flake-patched;
                };

                checks = import ./tests {
                  inherit llib;
                  pkgs = import inputs.nixpkgs { inherit system; };
                  lib = pkgs.lib;
                  nix-flake-patched = pkgs.nix-flake-patched;
                  gitignore-fmt = pkgs.gitignore-fmt;
                  org-fmt = pkgs.org-fmt;
                  text-fmt = pkgs.text-fmt;
                  treefmt-wrapper = pkgs.treefmt-wrapper;
                };

                treefmt = {
                  flakeCheck = true;
                  settings.excludes = [
                    "*.patch"
                    "LICENSE"
                    "flake.lock"
                    "pkgs/flake.lock"
                  ];
                };
              };
          };
        }
      );
}
