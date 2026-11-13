{ lib, overlayTree }:
let
  # A declared test tree fixes the selected paths. The final scope supplies
  # their values, but its additional members are not part of the selection.
  # recurseIntoAttrs adds metadata, not a check or a traversal instruction.
  testMembers_ = lib.filterAttrs (
    name_: value_: !(name_ == "recurseForDerivations" && value_ == true)
  );

  # Derivations are attribute sets, but are leaves of a test tree.
  describeType_ = value_: if lib.isDerivation value_ then "derivation" else builtins.typeOf value_;

  selectExplicit_ =
    path_: declared_: resolved_:
    if lib.isDerivation declared_ then
      if lib.isDerivation resolved_ then
        resolved_
      else
        builtins.throw "tests.mkChecks: expected a derivation at ${builtins.toJSON path_}, found ${describeType_ resolved_}"
    else if builtins.isAttrs declared_ then
      if builtins.isAttrs resolved_ && !lib.isDerivation resolved_ then
        selectExplicitMembers_ path_ declared_ resolved_
      else
        builtins.throw "tests.mkChecks: expected a non-derivation namespace at ${builtins.toJSON path_}, found ${describeType_ resolved_}"
    else
      builtins.throw "tests.mkChecks: invalid explicit check at ${builtins.toJSON path_}, found ${describeType_ declared_}";

  # Enumerate only declared members. In particular, an empty declaration
  # need not force the final root scope, and scope management members or
  # unselected dependencies (even recursive ones) are never traversed.
  # Declared namespaces must form a finite, acyclic tree.
  selectExplicitMembers_ =
    path_: declared_: resolved_:
    lib.mapAttrs (
      name_: child_:
      let
        childPath_ = path_ ++ [ name_ ];
      in
      selectExplicit_ childPath_ child_ (
        resolved_.${name_}
          or (builtins.throw "tests.mkChecks: missing explicit check at ${builtins.toJSON childPath_}")
      )
    ) (testMembers_ declared_);

  # Both trees select values from the same final scope. Merge namespaces,
  # never derivation attributes; an overlapping path denotes one test.
  # Visit both selected trees so an explicit subtree cannot hide an invalid
  # directory namespace through a shallow, lazy replacement. Inconsistent
  # node types would violate the shared-scope invariant.
  mergeCheckTrees_ =
    path_: trees_:
    lib.zipAttrsWith (
      name_: values_:
      if builtins.length values_ == 1 then
        builtins.head values_
      else if builtins.all lib.isDerivation values_ then
        builtins.head values_
      else if builtins.all (value_: builtins.isAttrs value_ && !lib.isDerivation value_) values_ then
        mergeCheckTrees_ (path_ ++ [ name_ ]) values_
      else
        builtins.throw "tests.mkChecks: incompatible selected values at ${
          builtins.toJSON (path_ ++ [ name_ ])
        }"
    ) trees_;

  # Flatten only the selected tree. The defensive invalid-leaf check guards
  # the invariant established by both selectors and the structural merge.
  flattenChecks_ =
    separator_: tree_:
    let
      collect_ =
        path_: value_:
        if lib.isDerivation value_ then
          [
            {
              name = builtins.concatStringsSep separator_ path_;
              inherit path_ value_;
            }
          ]
        else if builtins.isAttrs value_ then
          builtins.concatLists (
            lib.mapAttrsToList (name_: child_: collect_ (path_ ++ [ name_ ]) child_) value_
          )
        else
          builtins.throw "tests.mkChecks: invalid test at ${builtins.toJSON path_}";
      groups_ = lib.groupBy (entry_: entry_.name) (collect_ [ ] tree_);
      conflicts_ = lib.filterAttrs (unused_name_: entries_: builtins.length entries_ > 1) groups_;
    in
    if conflicts_ != { } then
      builtins.throw "tests.mkChecks: ambiguous flattened names: ${
        builtins.toJSON (lib.mapAttrs (unused_name_: map (entry_: entry_.path_)) conflicts_)
      }"
    else
      lib.mapAttrs (unused_name_: entries_: (builtins.head entries_).value_) groups_;
in
{
  mkChecks =
    {
      root,
      overlayFile,
      checks ? { },
      args ? { },
      separator ? "/",
    }:
    let
      tree_ = overlayTree.discoverTree { inherit root overlayFile; };
      overlays_ = overlayTree.mkOverlaysFromTree { tree = tree_; };
      newScope_ =
        extra_:
        lib.callPackageWith (
          lib.mergeAttrsList [
            args
            extra_
          ]
        );
      overlay_ = lib.composeManyExtensions (builtins.attrValues overlays_);
      # Keep the test definitions in the fixed point, without makeScope's
      # reserved `packages` member masking a same-named check.
      scope_ = lib.fix (
        final_:
        let
          initial_ = lib.mergeAttrsList [
            {
              callPackage = newScope_ final_;
              newScope =
                extra_:
                newScope_ (
                  lib.mergeAttrsList [
                    final_
                    extra_
                  ]
                );
            }
            args
            checks
          ];
        in
        lib.mergeAttrsList [
          initial_
          (overlay_ final_ initial_)
        ]
      );
      existing_ = selectExplicitMembers_ [ ] checks scope_;
      discovered_ = overlayTree.selectDerivations {
        tree = tree_;
        scope = scope_;
        context = "tests.mkChecks";
      };
    in
    # Unlike a nested test tree, the root must be a namespace. Validate it
    # without inspecting the final scope: empty discovery and declarations
    # must not force args or scope construction.
    if !(builtins.isAttrs checks) || lib.isDerivation checks then
      builtins.throw "tests.mkChecks: checks must be a non-derivation attribute set at [], found ${describeType_ checks}"
    else
      flattenChecks_ separator (mergeCheckTrees_ [ ] [ existing_ discovered_ ]);
}
