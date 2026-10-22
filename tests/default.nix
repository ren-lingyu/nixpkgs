{ llib }: { mergeAttrsRecursive = import ./merge-attrs-recursive.nix { inherit llib; }; }
