{
  inputs = {
    nixpkgs = {
      url = "git+https://github.com/NixOS/nixpkgs.git?ref=refs/heads/nixpkgs-unstable&shallow=1&rev=2074cc672349f14240fb7ea90d509e0b643e9dd4";
    };
    # Keep the upstream release's build dependencies independent of the caller's Nixpkgs.
    nix-2_35_6 = {
      url = "git+https://github.com/NixOS/nix.git?ref=refs/tags/2.35.6&shallow=1&rev=4c9c2490ff10c6fc30f9675273af989569cf37da";
    };
    flake-parts = {
      url = "git+https://github.com/hercules-ci/flake-parts.git?ref=refs/heads/main&shallow=1&rev=ea2630b7470978622c7689a1ff75d2b389175399";
    };
    treefmt-nix = {
      url = "git+https://github.com/numtide/treefmt-nix.git?ref=refs/heads/main&shallow=1&rev=0d6d739a833ba9a9c93034862e4a7b061a062a1c";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    elisp-autofmt = {
      url = "git+https://github.com/emacsmirror/elisp-autofmt.git?ref=refs/heads/master&shallow=1&rev=a41fe15d3d2c69a6f069bab4d90caab8a4b62be7";
      flake = false;
    };
    lisplens = {
      url = "git+https://github.com/rigortype/lisplens.git?ref=refs/tags/v0.6.0&shallow=1&rev=2662b944d8d93a2734bc78464864b140ec9e0b8f";
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
