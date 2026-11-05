{ extraArgs }: final_: prev_: {
  lisplens = final_.callPackage ./package.nix { src = extraArgs.sources.lisplens; };
}
