{ lib, overlayTree }:
let
  inherit (overlayTree)
    getDirectories_
    resolvePath_
    hasPath_
    hasEntries_
    ;

  selectPackages_ =
    node_: pkgs_:
    lib.mapAttrs
      (
        name_: child_:
        if !(builtins.hasAttr name_ pkgs_) then
          builtins.throw "packages.mkOverlays: namespace `${toString child_.path_}` does not exist in the package set"
        else if lib.isDerivation pkgs_.${name_} then
          if child_.hasDescendants then
            builtins.throw "packages.mkOverlays: derivation `${name_}` has descendant overlays in `${toString child_.path_}`"
          else
            pkgs_.${name_}
        else if builtins.isAttrs pkgs_.${name_} then
          selectPackages_ child_ pkgs_.${name_}
        else
          builtins.throw "packages.mkOverlays: `${toString child_.path_}` is not a package namespace"
      )
      (
        lib.filterAttrs (
          name_: child_:
          if child_.hasDescendants then
            true
          else if child_.hasOverlay then
            lib.isDerivation (pkgs_.${name_} or null)
          else
            false
        ) node_.children
      );

  validateGroup_ =
    overlays_: name_: config_:
    let
      fail_ = message_: builtins.throw "packages.mkOverlays: group `${name_}`: ${message_}";
      unknown_ = lib.subtractLists [ "include" "exclude" "export" "overlays" ] (
        builtins.attrNames config_
      );
      include_ = config_.include or (builtins.attrNames overlays_);
      exclude_ = config_.exclude or [ ];
      export_ = config_.export or false;
      externalOverlays_ = config_.overlays or [ ];
      unknownExcluded_ = lib.subtractLists (builtins.attrNames overlays_) exclude_;
      unknownIncluded_ = lib.subtractLists (builtins.attrNames overlays_) include_;
    in
    if !(builtins.isAttrs config_) then
      fail_ "expected an attribute set"
    else if unknown_ != [ ] then
      fail_ "unknown fields ${builtins.toJSON unknown_}"
    else if !(builtins.isList include_ && builtins.all builtins.isString include_) then
      fail_ "include must be a list of strings"
    else if !(builtins.isList exclude_ && builtins.all builtins.isString exclude_) then
      fail_ "exclude must be a list of strings"
    else if
      !(builtins.isList externalOverlays_ && builtins.all builtins.isFunction externalOverlays_)
    then
      fail_ "overlays must be a list of functions"
    else if !(builtins.isBool export_ || builtins.isString export_) then
      fail_ "export must be a boolean or a nonempty string"
    else if export_ == "" then
      fail_ "export name must not be empty"
    else if unknownIncluded_ != [ ] then
      fail_ "unknown included overlays ${builtins.toJSON unknownIncluded_}"
    else if unknownExcluded_ != [ ] then
      fail_ "unknown excluded overlays ${builtins.toJSON unknownExcluded_}"
    else
      {
        include = include_;
        exclude = exclude_;
        overlays = externalOverlays_;
        exportName = if export_ == true then "legacyPackages" else export_;
      };

  mkGroup_ =
    tree_: overlays_: name_: config_:
    let
      selected_ = lib.filterAttrs (
        name_: unused_: builtins.elem name_ config_.include && !(builtins.elem name_ config_.exclude)
      ) overlays_;
      groupTree_ = tree_ // {
        children = builtins.intersectAttrs selected_ tree_.children;
      };
      groupOverlay_ = lib.composeManyExtensions (builtins.attrValues selected_);
      exportName_ = config_.exportName;
    in
    lib.composeManyExtensions (
      config_.overlays
      ++ [ groupOverlay_ ]
      ++ lib.optional (exportName_ != false) (
        final_: prev_:
        if builtins.hasAttr exportName_ prev_ then
          builtins.throw "packages.mkOverlays: group `${name_}`: export name `${exportName_}` already exists"
        else
          { ${exportName_} = selectPackages_ groupTree_ final_; }
      )
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
  mkOverlays =
    {
      root,
      overlayFile,
      extraArgs ? { },
      groups ? { },
    }:
    let
      tree = overlayTree.discoverTree { inherit root overlayFile; };
      overlays_ = overlayTree.mkOverlaysFromTree {
        inherit tree extraArgs;
        implicitOverlays = {
          emacsPackages = import ./rules/emacsPackages.nix;
          texlivePackages =
            { }:
            import ./rules/texlivePackages.nix {
              selectPackages = selectPackages_ tree.children.texlivePackages;
            };
        };
      };
      configs_ = lib.mapAttrs (validateGroup_ overlays_) groups;
    in
    if !(builtins.isAttrs groups) then
      builtins.throw "packages.mkOverlays: groups must be an attribute set"
    else if groups == { } then
      overlays_
    else
      builtins.deepSeq configs_ (lib.mapAttrs (mkGroup_ tree overlays_) configs_);

  mkNixosModule = { root, modulePath }: mkModule_ modulePath root;

  mkHomeModule = { root, modulePath }: mkModule_ modulePath root;
}
