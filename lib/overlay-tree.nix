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

  isOverlayFactory_ =
    overlayFile_: root_:
    if hasPath_ overlayFile_ root_ then
      isFactory_ (import (resolvePath_ overlayFile_ root_))
    else
      false;

  instantiateOverlay_ =
    overlayFile_: extraArgs_: root_: constructor_:
    let
      formalArgs_ = builtins.functionArgs constructor_;
      unknownArgs_ = lib.subtractLists [ "extraArgs" "descendantOverlay" ] (
        builtins.attrNames formalArgs_
      );
      constructorArgs_ =
        lib.optionalAttrs (formalArgs_ ? extraArgs) { extraArgs = extraArgs_; }
        // lib.optionalAttrs (formalArgs_ ? descendantOverlay) {
          descendantOverlay = mkOverlay_ overlayFile_ extraArgs_ root_;
        };
    in
    if unknownArgs_ != [ ] then
      builtins.throw "overlays.mkOverlay: unknown constructor arguments ${builtins.toJSON unknownArgs_} at `${toString root_}`"
    else
      constructor_ constructorArgs_;

  loadOverlay_ =
    overlayFile_: extraArgs_: root_:
    instantiateOverlay_ overlayFile_ extraArgs_ root_ (import (resolvePath_ overlayFile_ root_));

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
    overlayFile_: extraArgs_: name_: root_:
    let
      overlay_ = mkOverlay_ overlayFile_ extraArgs_ root_;
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
    overlayFile_: extraArgs_: root_:
    let
      directories_ = getDirectories_ root_;

      localOverlays_ = lib.mapAttrsToList (
        unused_name_: child_: loadOverlay_ overlayFile_ extraArgs_ child_
      ) (lib.filterAttrs (unused_name_: child_: hasPath_ overlayFile_ child_) directories_);

      namespaceOverlays_ =
        lib.mapAttrsToList (name_: child_: mkNamespaceOverlay_ overlayFile_ extraArgs_ name_ child_)
          (
            lib.filterAttrs (
              unused_name_: child_:
              if isOverlayFactory_ overlayFile_ child_ then false else hasEntries_ overlayFile_ child_
            ) directories_
          );
    in
    lib.composeManyExtensions (
      builtins.concatLists [
        localOverlays_
        namespaceOverlays_
      ]
    );

  mkOverlays_ =
    overlayFile_: extraArgs_: root_: implicitOverlays_:
    lib.mapAttrs
      (
        name_: child_:
        let
          hasDescendants_ = hasEntries_ overlayFile_ child_;
          localOverlay_ =
            if hasPath_ overlayFile_ child_ then
              import (resolvePath_ overlayFile_ child_)
            else if hasDescendants_ && builtins.hasAttr name_ implicitOverlays_ then
              implicitOverlays_.${name_}
            else
              null;
          ownsDescendants_ = localOverlay_ != null && isFactory_ localOverlay_;
        in
        lib.composeManyExtensions (
          builtins.concatLists [
            (lib.optional (localOverlay_ != null) (
              instantiateOverlay_ overlayFile_ extraArgs_ child_ localOverlay_
            ))
            (lib.optional (hasDescendants_ && !ownsDescendants_) (
              mkNamespaceOverlay_ overlayFile_ extraArgs_ name_ child_
            ))
          ]
        )
      )
      (
        lib.filterAttrs (
          unused_name_: child_:
          builtins.any (x_: x_) [
            (hasPath_ overlayFile_ child_)
            (hasEntries_ overlayFile_ child_)
          ]
        ) (getDirectories_ root_)
      );

in
{
  inherit
    getDirectories_
    resolvePath_
    hasPath_
    hasEntries_
    ;

  mkOverlays =
    {
      root,
      overlayFile,
      implicitOverlays ? { },
      extraArgs ? { },
    }:
    mkOverlays_ overlayFile extraArgs root implicitOverlays;
}
