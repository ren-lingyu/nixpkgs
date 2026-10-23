final: prev: {
  overlays = final.callPackage (
    {
      lib,
      overlayTree,
      mkResultCheck,
    }:
    mkResultCheck "overlays" (import ./cases.nix { inherit lib overlayTree; })
  ) { };
}
