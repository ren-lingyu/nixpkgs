{ extraArgs }: final_: prev_: {
  treefmt-wrapper = final_.callPackage ./package.nix {
    inherit (extraArgs) treefmt-nix-lib;
    imports = [ ./config.nix ];
  };
}
