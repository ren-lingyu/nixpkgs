{ }: final: prev: {
  nix-flake-patched = final.callPackage ./check.nix { nix-flake-patched = prev.nix-flake-patched; };
}
