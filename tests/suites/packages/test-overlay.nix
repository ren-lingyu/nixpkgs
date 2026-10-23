final: prev: {
  packages = final.callPackage (
    {
      llib,
      lib,
      pkgs,
      mkResultCheck,
    }:
    mkResultCheck "packages" (import ./cases.nix { inherit llib lib pkgs; })
  ) { };
}
