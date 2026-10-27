{
  fetchpatch,
  lib,
  nix,
}:
let
  # Nix 2.35.3: recheck both patches whenever the 2.35 series is updated.
  # Remove each patch separately once its fix is included upstream.
  patches = [
    # https://github.com/NixOS/nix/issues/4811
    ./patches/fix-circular-import.patch
    # https://github.com/NixOS/nix/pull/15982 (issue #14762)
    (fetchpatch {
      name = "fix-nested-relative-path.patch";
      url = "https://github.com/NixOS/nix/commit/3337ecd3b0ce0dea6200364ccb2afd82f43a692f.patch";
      hash = "sha256-c9BGEKrtwRw6+y8AtALfWgwXhuydASQEwTHu851Yi70=";
      includes = [ "src/libflake/flake.cc" ];
    })
  ];
  patchedNix = nix.appendPatches patches;
  passthru = patchedNix.passthru // {
    baseNix = nix;
    inherit patches;
  };
in
# Preserve the upstream overriding methods and propagate metadata to all outputs.
lib.extendDerivation true (passthru // { inherit passthru; }) patchedNix
