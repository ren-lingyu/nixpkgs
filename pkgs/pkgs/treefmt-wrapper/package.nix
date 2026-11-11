{
  pkgs,
  treefmt-nix-lib,
  imports,
}:
(treefmt-nix-lib.mkWrapper pkgs {
  inherit imports;
  projectRootFile = null;
}).overrideAttrs
  (old: {
    passthru = (old.passthru or { }) // {
      inherit imports;
    };
  })
