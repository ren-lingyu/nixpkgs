{ lib }: {

  mergeAttrsRecursive = import ./merge-attrs-recursive.nix;

  packages = import ./packages { inherit lib; };

}
