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
            lpkgs = import ./pkgs { inherit llib; };
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
              inherit (lpkgs) overlays;

              lib = toplevel.llib.mergeAttrsRecursive { allowOverrides = false; } [
                toplevel.llib
                {
                  mkFlake =
                    nixpkgs:
                    {
                      moduleLocation,
                      llib ? { },
                      lpkgs ? { },
                      ...
                    }@args:
                    module:
                    assert inputs.nixpkgs.lib.assertMsg (args ? moduleLocation)
                      "mkFlake: moduleLocation must be explicitly specified, such as `moduleLocation = ./flake.nix;` or `moduleLocation = __curPos.file;`.";
                    inputs.flake-parts.lib.mkFlake
                      (toplevel.llib.mergeAttrsRecursive { allowOverrides = true; } [
                        {
                          specialArgs = {
                            lib = nixpkgs.lib;
                            inherit llib lpkgs;
                          };
                        }
                        (builtins.removeAttrs args [
                          "llib"
                          "lpkgs"
                        ])
                      ])
                      {
                        imports = [
                          {
                            perSystem =
                              {
                                llib,
                                lpkgs,
                                pkgs,
                                lib,
                                system,
                                config,
                                ...
                              }:
                              {
                                options = {
                                  nixpkgs = {
                                    overlays = lib.mkOption {
                                      type = lib.types.listOf (
                                        lib.types.functionTo (lib.types.functionTo (lib.types.lazyAttrsOf lib.types.unspecified))
                                      );
                                      default = [ ];
                                    };
                                  };
                                };
                                config = {
                                  _module.args = {
                                    pkgs = nixpkgs.lib.mkForce (
                                      import nixpkgs {
                                        inherit system;
                                        overlays = config.nixpkgs.overlays;
                                      }
                                    );
                                    lib = nixpkgs.lib.mkForce nixpkgs.lib;
                                  };
                                };
                              };
                          }
                          inputs.flake-parts.flakeModules.modules
                          inputs.treefmt-nix.flakeModule
                          {
                            perSystem = {
                              nixpkgs.overlays = [ toplevel.lpkgs.overlays.default ];
                            };
                          }
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
