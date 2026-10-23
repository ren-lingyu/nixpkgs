{
  llib,
  lib,
  pkgs,
}:
let
  root = ./fixtures/test-api/basic;
  overlayFile = "overlay.nix";
  checks = llib.tests.mkChecks {
    inherit root overlayFile;
    args = {
      inherit lib pkgs llib;
      inherit (pkgs) writeText;
    };
  };
in
lib.mapAttrs' (name: value: lib.nameValuePair "testApi/${name}" value) checks
