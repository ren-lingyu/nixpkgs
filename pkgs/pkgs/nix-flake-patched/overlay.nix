{ extraArgs }: final_: prev_: {
  nix-flake-patched = final_.callPackage ./package.nix {
    nix = extraArgs.nix-2_35_6.${final_.stdenv.hostPlatform.system};
  };
}
