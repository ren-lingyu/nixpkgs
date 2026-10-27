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
              lib = toplevel.llib.mergeAttrsRecursive { allowOverrides = false; } [
                toplevel.llib
                {
                  mkFlake =
                    nixpkgs: argsFun: module:
                    let
                      args = argsFun { lib = nixpkgs.lib; };
                      specialArgs = toplevel.llib.mergeAttrsRecursive { allowOverrides = true; } [
                        {
                          lib = nixpkgs.lib;
                          llib = args.llib or { };
                          lpkgs = args.lpkgs or { };
                        }
                        (args.specialArgs or { })
                      ];
                      flakeArgs = toplevel.llib.mergeAttrsRecursive { allowOverrides = true; } [
                        { inherit specialArgs; }
                        (builtins.removeAttrs args [
                          "llib"
                          "lpkgs"
                        ])
                      ];
                    in
                    assert builtins.isAttrs args;
                    assert
                      (builtins.filter (name: !(builtins.hasAttr name args)) [
                        "inputs"
                        "moduleLocation"
                      ]) == [ ];
                    assert !(args ? specialArgs) || builtins.isAttrs args.specialArgs;
                    inputs.flake-parts.lib.mkFlake flakeArgs {
                      imports = [
                        {
                          imports = [ inputs.treefmt-nix.flakeModule ];

                          config.perSystem =
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
                                };

                                nixpkgs.overlays = with toplevel.lpkgs.overlays; [
                                  treefmt
                                  nix
                                ];

                                devShells = {
                                  nix = pkgs.mkShellNoCC {
                                    packages = [ pkgs.nix-flake-patched ];

                                    shellHook = ''export PATH="${pkgs.nix-flake-patched}/bin:$PATH"'';
                                  };
                                };
                              };
                            };
                        }
                        ./modules/fp/treefmt
                        module
                      ];
                    };
                }
              ];
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
                _module.args = {
                  pkgs = import inputs.nixpkgs {
                    inherit system;
                    overlays = [ lpkgs.overlays.legacy ];
                  };
                };

                legacyPackages = pkgs.legacyPackages;
              };
          };
        }
      );
}
