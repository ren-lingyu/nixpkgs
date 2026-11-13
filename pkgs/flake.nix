{
  inputs = {
    nixpkgs = {
      url = "git+https://github.com/NixOS/nixpkgs.git?ref=refs/heads/nixpkgs-unstable&shallow=1";
    };
    # Keep the upstream release's build dependencies independent of the caller's Nixpkgs.
    nix-2_35_6 = {
      url = "git+https://github.com/NixOS/nix.git?ref=refs/tags/2.35.6&shallow=1&rev=4c9c2490ff10c6fc30f9675273af989569cf37da";
    };
    flake-parts = {
      url = "git+https://github.com/hercules-ci/flake-parts.git?ref=refs/heads/main&shallow=1";
    };
    treefmt-nix = {
      url = "git+https://github.com/numtide/treefmt-nix.git?ref=refs/heads/main&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    elisp-autofmt = {
      url = "git+https://github.com/emacsmirror/elisp-autofmt.git?ref=refs/heads/master&shallow=1";
      flake = false;
    };
    lisplens = {
      url = "git+https://github.com/rigortype/lisplens.git?ref=refs/tags/v0.6.0&shallow=1";
      flake = false;
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      llib = import ./lib { lib = inputs.nixpkgs.lib; };
      lpkgs = import ./pkgs {
        llib = { inherit (llib) packages; };
        sources = { inherit (inputs) elisp-autofmt lisplens; };
        nix-2_35_6 = builtins.mapAttrs (_: packages: packages.nix) inputs.nix-2_35_6.packages;
        treefmt-nix-lib = inputs.treefmt-nix.lib;
      };
    in
    {
      lib = {
        inherit (llib)
          mergeAttrsRecursive
          overlays
          packages
          tests
          ;
        mkFlake =
          nixpkgs: argsFun: module:
          llib._makeMkFlake {
            inherit nixpkgs argsFun module;

            flakePartsMkFlake = inputs.flake-parts.lib.mkFlake;

            overlays = [
              lpkgs.overlays.treefmt
              lpkgs.overlays.nix
            ];

            modules = [
              inputs.treefmt-nix.flakeModule
              ({ lib, moduleLocation, ... }: {
                config.perSystem = { pkgs, ... }: {
                  treefmt = {
                    imports = pkgs.treefmt-wrapper.passthru.imports;
                    flakeFormatter = true;
                    flakeCheck = lib.mkDefault true;
                    projectRootFile = builtins.baseNameOf (builtins.toString moduleLocation);
                  };

                  devShells = {
                    nix = pkgs.mkShellNoCC {
                      packages = [ pkgs.nix-flake-patched ];
                      shellHook = ''export PATH="${pkgs.nix-flake-patched}/bin:$PATH"'';
                    };
                  };
                };
              })
            ];
          };
      };

      inherit (lpkgs) overlays;
    };
}
