{ lib, overlayTree }:
let
  inherit (overlayTree) getDirectories_ hasPath_ hasEntries_;

  collect_ =
    overlayFile_: separator_: path_: root_: scope_:
    builtins.concatLists (
      lib.mapAttrsToList (
        name_: child_:
        let
          path = path_ ++ [ name_ ];
          label = builtins.toJSON path;
          value = scope_.${name_} or null;
        in
        if hasEntries_ overlayFile_ child_ then
          if !(builtins.hasAttr name_ scope_) then
            builtins.throw "tests.mkChecks: missing namespace at ${label}"
          else if !(builtins.isAttrs value) || lib.isDerivation value then
            builtins.throw "tests.mkChecks: expected a non-derivation namespace at ${label}"
          else
            collect_ overlayFile_ separator_ path child_ value
        else if hasPath_ overlayFile_ child_ && lib.isDerivation value then
          [
            {
              name = builtins.concatStringsSep separator_ path;
              inherit value;
            }
          ]
        else
          [ ]
      ) (getDirectories_ root_)
    );
in
{
  mkOverlays = { root, overlayFile }: overlayTree.mkOverlays { inherit root overlayFile; };

  mkChecks =
    {
      root,
      overlayFile,
      scope,
      separator ? "/",
    }:
    builtins.listToAttrs (collect_ overlayFile separator [ ] root scope);
}
