{
  llib,
  lib,
  pkgs,
  nix-flake-patched,
}:
let
  mkResultCheck_ =
    name_: results_:
    builtins.seq results_ (pkgs.writeText "${name_}-tests.json" (builtins.toJSON results_));
  root_ = ./suites;
  overlayFile_ = "test-overlay.nix";
  checks_ = llib.tests.mkChecks {
    root = root_;
    overlayFile = overlayFile_;
    checks = directChecks_;
    args = {
      inherit
        llib
        lib
        pkgs
        nix-flake-patched
        ;
      mkResultCheck = mkResultCheck_;
    };
  };
  expectedNames_ = lib.sort builtins.lessThan (
    [
      "mergeAttrsRecursive"
      "nix-flake-patched"
      "overlays"
      "packages"
    ]
    ++ builtins.attrNames directChecks_
  );
  directChecks_ = {
    testApi = mkResultCheck_ "testApi" (import ./test-api.nix { inherit llib lib pkgs; });
  }
  // (import ./test-checks.nix { inherit llib lib pkgs; });
in
if builtins.attrNames checks_ != expectedNames_ then
  builtins.throw "tests: expected suite checks ${builtins.toJSON expectedNames_}, got ${builtins.toJSON (builtins.attrNames checks_)}"
else
  checks_
