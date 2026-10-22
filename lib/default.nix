{ lib }: {

  mergeAttrsRecursive = import ./merge-attrs-recursive.nix;

  packages = import ./packages.nix { inherit lib; };

}
