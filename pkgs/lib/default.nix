{ lib }:
let
  overlayTree = import ./overlay-tree.nix { inherit lib; };
in
{
  mergeAttrsRecursive = import ./merge-attrs-recursive.nix;
  overlays = { inherit (overlayTree) mkOverlays; };
  packages = import ./packages { inherit lib overlayTree; };
  tests = import ./tests.nix { inherit lib overlayTree; };
}
