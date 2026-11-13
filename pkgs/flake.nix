{
  inputs = {
    nixpkgs = {
      url = "git+https://github.com/NixOS/nixpkgs.git?ref=refs/heads/nixpkgs-unstable&shallow=1";
    };
    # Keep the upstream release's build dependencies independent of the caller's Nixpkgs.
    nix-2_35_6 = {
      url = "git+https://github.com/NixOS/nix.git?ref=refs/tags/2.35.6&shallow=1";
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
    inputs.flake-parts.lib.mkFlake
      {
        inherit inputs;

        specialArgs =
          let
            lib = inputs.nixpkgs.lib;
          in
          rec {
            llib = import ./lib { inherit lib; };
            lpkgs = import ./pkgs {
              inherit llib;
              sources = { inherit (inputs) elisp-autofmt lisplens; };
              nix-2_35_6 = builtins.mapAttrs (_: packages: packages.nix) inputs.nix-2_35_6.packages;
              treefmt-nix-lib = inputs.treefmt-nix.lib;
            };
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
                      missingArgs = builtins.filter (name: !(builtins.hasAttr name args)) [
                        "inputs"
                        "moduleLocation"
                      ];
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
                    assert nixpkgs.lib.assertMsg (builtins.isFunction argsFun)
                      "mkFlake: the second argument must be a function accepting { lib } and returning an attribute set (for example, { lib }: { inherit inputs; moduleLocation = ./flake.nix; }).";
                    assert nixpkgs.lib.assertMsg (builtins.isAttrs args)
                      "mkFlake: the argument function must return an attribute set.";
                    assert nixpkgs.lib.assertMsg (missingArgs == [ ])
                      "mkFlake: the argument function result is missing required attributes: ${builtins.toJSON missingArgs}. Provide inputs and moduleLocation in the returned attribute set (for example, moduleLocation = ./flake.nix; or moduleLocation = __curPos.file;).";
                    assert nixpkgs.lib.assertMsg (
                      !(args ? specialArgs) || builtins.isAttrs args.specialArgs
                    ) "mkFlake: specialArgs in the argument function result must be an attribute set.";
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
