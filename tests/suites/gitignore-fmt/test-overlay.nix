{ }: final: prev: {
  gitignore-fmt = final.callPackage ./check.nix { gitignore-fmt = prev.gitignore-fmt; };
}
