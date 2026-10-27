{ }: final_: prev_: {
  nix-flake-patched = final_.callPackage ./package.nix { nix = final_.nixVersions.nix_2_35; };
}
