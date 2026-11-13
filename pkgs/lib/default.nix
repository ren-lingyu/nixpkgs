{ lib }:
let
  overlayTree = import ./overlay-tree.nix { inherit lib; };
in
{
  _makeMkFlake = import ./make-mk-flake.nix;
  mergeAttrsRecursive = import ./merge-attrs-recursive.nix;
  overlays = { inherit (overlayTree) mkOverlays; };
  packages = import ./packages { inherit lib overlayTree; };
  tests = import ./tests.nix { inherit lib overlayTree; };
}
