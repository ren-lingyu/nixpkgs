{ extraArgs }: final_: prev_: {
  nix-flake-patched = final_.callPackage ./package.nix {
    nix = extraArgs.nix-2_35_3.legacyPackages.${final_.stdenv.hostPlatform.system}.nixVersions.nix_2_35;
  };
}
