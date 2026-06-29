{ pkgs, markerNames ? [ "recurseForDerivations" ] } : let

  lib = pkgs.lib;

in (rec {

  stripPackageTreeMarkers = import ./strip-package-tree-markers.nix { inherit lib; } markerNames;

  mkRecursiveOverlay = import ./mk-recursive-overlay.nix { inherit lib; } stripPackageTreeMarkers;
  
})
