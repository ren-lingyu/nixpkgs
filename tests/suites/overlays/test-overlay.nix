{ }: final: prev: {
  overlays = final.callPackage (
    {
      lib,
      llib,
      mkResultCheck,
    }:
    mkResultCheck "overlays" (import ./cases.nix { inherit lib llib; })
  ) { };
}
