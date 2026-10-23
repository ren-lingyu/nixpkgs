{
  llib,
  lib,
  pkgs,
  overlayTree,
}:
let
  mkResultCheck_ =
    name_: results_:
    builtins.seq results_ (pkgs.writeText "${name_}-tests.json" (builtins.toJSON results_));
  root_ = ./suites;
  overlayFile_ = "test-overlay.nix";
  overlays_ = llib.tests.mkOverlays {
    root = root_;
    overlayFile = overlayFile_;
  };
  scope_ =
    (lib.makeScope pkgs.newScope (_: {
      inherit
        llib
        lib
        pkgs
        overlayTree
        ;
      mkResultCheck = mkResultCheck_;
    })).overrideScope
      (lib.composeManyExtensions (builtins.attrValues overlays_));
  checks_ = llib.tests.mkChecks {
    root = root_;
    overlayFile = overlayFile_;
    # makeScope reserves `packages`; extract the applied suite definitions.
    scope = scope_.packages scope_;
  };
  expectedNames_ = [
    "mergeAttrsRecursive"
    "overlays"
    "packages"
  ];
  directChecks_ = {
    testApi = mkResultCheck_ "testApi" (import ./test-api.nix { inherit llib lib pkgs; });
  }
  // (import ./test-checks.nix { inherit llib lib pkgs; });
in
if builtins.attrNames checks_ != expectedNames_ then
  builtins.throw "tests: expected ordinary suite checks ${builtins.toJSON expectedNames_}, got ${builtins.toJSON (builtins.attrNames checks_)}"
else
  checks_ // directChecks_
