{ extraArgs }: final_: prev_: {
  elisp-autofmt = final_.callPackage ./package.nix { src = extraArgs.sources.elisp-autofmt; };
}
