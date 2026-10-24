{ lib }:
let
  getDirectories_ =
    path_:
    lib.mapAttrs (name_: unused_type_: path_ + "/${name_}") (
      lib.filterAttrs (unused_name_: type_: type_ == "directory") (builtins.readDir path_)
    );

  resolvePath_ = relativePath_: path_: path_ + "/${relativePath_}";

  hasPath_ = relativePath_: path_: builtins.pathExists (resolvePath_ relativePath_ path_);

  hasEntries_ =
    relativePath_: path_:
    builtins.any (
      child_: if hasPath_ relativePath_ child_ then true else hasEntries_ relativePath_ child_
    ) (builtins.attrValues (getDirectories_ path_));

  isFactory_ = overlay_: (builtins.functionArgs overlay_) ? descendantOverlay;

  # Each directory is described once. Children, imports and constructor metadata
  # stay lazy; discovering a subtree never instantiates its constructors.
  discoverTree =
    { root, overlayFile }:
    let
      describe_ = path_: rec {
        inherit path_;
        hasOverlay = hasPath_ overlayFile path_;
        constructor = import (resolvePath_ overlayFile path_);
        ownsDescendants = hasOverlay && isFactory_ constructor;
        children = lib.mapAttrs (unused_name_: describe_) (getDirectories_ path_);
        hasDescendants = builtins.any (child_: child_.hasOverlay || child_.hasDescendants) (
          builtins.attrValues children
        );
      };
    in
    describe_ root;

  instantiateOverlay_ =
    extraArgs_: node_: constructor_:
    let
      formalArgs_ = builtins.functionArgs constructor_;
      unknownArgs_ = lib.subtractLists [ "extraArgs" "descendantOverlay" ] (
        builtins.attrNames formalArgs_
      );
      constructorArgs_ =
        lib.optionalAttrs (formalArgs_ ? extraArgs) { extraArgs = extraArgs_; }
        // lib.optionalAttrs (formalArgs_ ? descendantOverlay) {
          descendantOverlay = mkOverlay_ extraArgs_ node_;
        };
    in
    if unknownArgs_ != [ ] then
      builtins.throw "overlays.mkOverlay: unknown constructor arguments ${builtins.toJSON unknownArgs_} at `${toString node_.path_}`"
    else
      constructor_ constructorArgs_;

  mkAttrsetOverlay_ =
    final_: previous_: overlay_:
    if !(final_ ? newScope) then
      builtins.throw "overlays.mkOverlay: parent package set does not provide `newScope`"
    else
      let
        scope_ = lib.makeScope final_.newScope (
          self_:
          lib.mergeAttrsList [
            previous_
            (overlay_ self_ previous_)
          ]
        );
      in
      lib.mergeAttrsList [
        previous_
        (overlay_ scope_ previous_)
      ];

  mkNamespaceOverlay_ =
    extraArgs_: name_: node_:
    let
      overlay_ = mkOverlay_ extraArgs_ node_;
    in
    final_: prev_:
    lib.setAttrByPath [ name_ ] (
      if !(builtins.hasAttr name_ prev_) then
        if !(final_ ? newScope) then
          builtins.throw "overlays.mkOverlay: parent package set does not provide `newScope` for `${name_}`"
        else
          lib.makeScope final_.newScope (self_: overlay_ self_ { })
      else if !(builtins.isAttrs prev_.${name_}) then
        builtins.throw "overlays.mkOverlay: `${name_}` already exists and is not an attribute set"
      else if lib.isDerivation prev_.${name_} then
        builtins.throw "overlays.mkOverlay: `${name_}` already exists and is a derivation"
      else if prev_.${name_} ? overrideScope then
        prev_.${name_}.overrideScope overlay_
      else
        mkAttrsetOverlay_ final_ prev_.${name_} overlay_
    );

  mkOverlay_ =
    extraArgs_: node_:
    let
      localOverlays_ = lib.mapAttrsToList (
        unused_name_: child_: instantiateOverlay_ extraArgs_ child_ child_.constructor
      ) (lib.filterAttrs (unused_name_: child_: child_.hasOverlay) node_.children);

      namespaceOverlays_ =
        lib.mapAttrsToList (name_: child_: mkNamespaceOverlay_ extraArgs_ name_ child_)
          (
            lib.filterAttrs (
              unused_name_: child_: !child_.ownsDescendants && child_.hasDescendants
            ) node_.children
          );
    in
    lib.composeManyExtensions (
      builtins.concatLists [
        localOverlays_
        namespaceOverlays_
      ]
    );

  mkOverlaysFromTree =
    {
      tree,
      extraArgs ? { },
      implicitOverlays ? { },
    }:
    lib.mapAttrs
      (
        name_: child_:
        let
          hasDescendants_ = child_.hasDescendants;
          localOverlay_ =
            if child_.hasOverlay then
              child_.constructor
            else if hasDescendants_ && builtins.hasAttr name_ implicitOverlays then
              implicitOverlays.${name_}
            else
              null;
          ownsDescendants_ = localOverlay_ != null && isFactory_ localOverlay_;
        in
        lib.composeManyExtensions (
          builtins.concatLists [
            (lib.optional (localOverlay_ != null) (instantiateOverlay_ extraArgs child_ localOverlay_))
            (lib.optional (hasDescendants_ && !ownsDescendants_) (mkNamespaceOverlay_ extraArgs name_ child_))
          ]
        )
      )
      (lib.filterAttrs (unused_name_: child_: child_.hasOverlay || child_.hasDescendants) tree.children);

in
{
  inherit
    getDirectories_
    resolvePath_
    hasPath_
    hasEntries_
    discoverTree
    mkOverlaysFromTree
    ;

  mkOverlays =
    {
      root,
      overlayFile,
      implicitOverlays ? { },
      extraArgs ? { },
    }:
    mkOverlaysFromTree {
      tree = discoverTree { inherit root overlayFile; };
      inherit extraArgs implicitOverlays;
    };
}
