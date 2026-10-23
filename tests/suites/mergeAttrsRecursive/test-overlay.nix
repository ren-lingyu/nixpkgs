{ }: final: prev: {
  mergeAttrsRecursive = final.callPackage (
    { llib, mkResultCheck }: mkResultCheck "mergeAttrsRecursive" (import ./cases.nix { inherit llib; })
  ) { };
}
