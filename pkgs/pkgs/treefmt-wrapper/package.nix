{
  pkgs,
  treefmt-nix-lib,
  imports,
}:
(treefmt-nix-lib.mkWrapper pkgs {
  inherit imports;
  projectRootFile = null;
}).overrideAttrs
  (
    final: old: {
      passthru = (old.passthru or { }) // {
        inherit imports;
        tests = (old.passthru.tests or { }) // {
          bibtex = pkgs.callPackage ./tests/check.nix { treefmt-wrapper = final.finalPackage; };
        };
      };
    }
  )
