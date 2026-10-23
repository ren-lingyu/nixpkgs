{
  llib,
  lib,
  pkgs,
}:
let
  root = ./fixtures/test-api/basic;
  overlayFile = "overlay.nix";
  overlays = llib.tests.mkOverlays { inherit root overlayFile; };
  scope =
    (lib.makeScope pkgs.newScope (_: {
      inherit lib pkgs llib;
    })).overrideScope
      (lib.composeManyExtensions (builtins.attrValues overlays));
  checks = llib.tests.mkChecks { inherit root overlayFile scope; };
in
lib.mapAttrs' (name: value: lib.nameValuePair "testApi/${name}" value) checks
