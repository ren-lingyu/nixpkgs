{
  nixpkgs,
  argsFun,
  module,
  flakePartsMkFlake,
  modules,
  overlays,
}:
let
  mergeAttrsRecursive = import ./merge-attrs-recursive.nix;

  args = argsFun { lib = nixpkgs.lib; };

  missingArgs = builtins.filter (name: !(builtins.hasAttr name args)) [
    "inputs"
    "moduleLocation"
  ];

  specialArgs = mergeAttrsRecursive { allowOverrides = true; } [
    {
      lib = nixpkgs.lib;
      llib = args.llib or { };
      lpkgs = args.lpkgs or { };
    }
    (args.specialArgs or { })
  ];

  flakeArgs = mergeAttrsRecursive { allowOverrides = true; } [
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
flakePartsMkFlake flakeArgs {
  imports = [
    {
      config.perSystem =
        {
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

            nixpkgs.overlays = overlays;
          };
        };
    }
  ]
  ++ modules
  ++ [ module ];
}
