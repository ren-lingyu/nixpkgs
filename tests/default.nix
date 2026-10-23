{
  llib,
  lib,
  pkgs,
  overlayTree,
}:
{
  mergeAttrsRecursive = import ./merge-attrs-recursive.nix { inherit llib; };
  overlays = import ./overlays.nix { inherit lib overlayTree; };
  packages = import ./packages.nix { inherit llib lib pkgs; };
}
