{ lib, overlayTree }:
let
  inherit (overlayTree)
    getDirectories_
    resolvePath_
    hasPath_
    hasEntries_
    ;

  mkLegacyPackages_ =
    overlayFile_: pkgs_: root_:
    lib.mapAttrs
      (
        name_: child_:
        if !(builtins.hasAttr name_ pkgs_) then
          builtins.throw "packages.mkLegacyPackages: `${name_}` does not exist in the package set"
        else if lib.isDerivation pkgs_.${name_} then
          if hasEntries_ overlayFile_ child_ then
            builtins.throw "packages.mkLegacyPackages: derivation `${name_}` has descendant overlays in `${toString child_}`"
          else
            pkgs_.${name_}
        else if builtins.isAttrs pkgs_.${name_} then
          mkLegacyPackages_ overlayFile_ pkgs_.${name_} child_
        else
          builtins.throw "packages.mkLegacyPackages: `${name_}` is not a package namespace"
      )
      (
        lib.filterAttrs (
          name_: child_:
          if hasEntries_ overlayFile_ child_ then
            true
          else if hasPath_ overlayFile_ child_ then
            lib.isDerivation (pkgs_.${name_} or null)
          else
            false
        ) (getDirectories_ root_)
      );

  mkModule_ = modulePath_: root_: {
    imports = builtins.concatLists (
      lib.mapAttrsToList (
        unused_name_: child_:
        if hasPath_ modulePath_ child_ then
          if hasEntries_ modulePath_ child_ then
            builtins.throw "packages.mkModule: module in `${toString child_}` has nested modules"
          else
            [ (resolvePath_ modulePath_ child_) ]
        else
          (mkModule_ modulePath_ child_).imports
      ) (getDirectories_ root_)
    );
  };
in
{
  mkLegacyPackages =
    {
      root,
      pkgs,
      overlayFile,
    }:
    mkLegacyPackages_ overlayFile pkgs root;

  mkOverlays =
    {
      root,
      overlayFile,
      extraArgs ? { },
    }:
    overlayTree.mkOverlays {
      inherit root overlayFile extraArgs;
      implicitOverlays = {
        emacsPackages = import ./rules/emacsPackages.nix;
        texlivePackages =
          { }:
          import ./rules/texlivePackages.nix {
            selectPackages = pkgs_: mkLegacyPackages_ overlayFile pkgs_ (resolvePath_ "texlivePackages" root);
          };
      };
    };

  mkNixosModule = { root, modulePath }: mkModule_ modulePath root;

  mkHomeModule = { root, modulePath }: mkModule_ modulePath root;
}
