{
  llib,
  lib,
  pkgs,
}:
{
  mergeAttrsRecursive = import ./merge-attrs-recursive.nix { inherit llib; };
  packages = import ./packages.nix { inherit llib lib pkgs; };
}
