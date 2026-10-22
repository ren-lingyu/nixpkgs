{ allowOverrides ? false }:
let
  isMergeable_ = value_: builtins.isAttrs value_ && (value_.type or null) != "derivation";

  leaf_ = value_: {
    value = value_;
    checked = true;
  };

  # A higher-priority leaf replaces the entire lower-priority subtree.
  takeMergeable_ =
    values_:
    if values_ == [ ] || !(isMergeable_ (builtins.head values_)) then
      [ ]
    else
      [ (builtins.head values_) ] ++ takeMergeable_ (builtins.tail values_);

  merge_ =
    path_: sets_:
    let
      children_ = builtins.zipAttrsWith (
        name_: values_:
        let
          childPath_ = path_ ++ [ name_ ];
        in
        if builtins.length values_ == 1 then
          leaf_ (builtins.head values_)
        else if allowOverrides then
          if isMergeable_ (builtins.head values_) then
            merge_ childPath_ (takeMergeable_ values_)
          else
            leaf_ (builtins.head values_)
        else if builtins.all isMergeable_ values_ then
          merge_ childPath_ values_
        else
          builtins.throw "mergeAttrsRecursive: conflicting definitions at ${builtins.toJSON childPath_}"
      ) sets_;
    in
    {
      value = builtins.mapAttrs (unused_name_: child_: child_.value) children_;
      checked = builtins.all (child_: child_.checked) (builtins.attrValues children_);
    };
in
# Validate every overlapping path before returning, without forcing unique leaves.
# Derivations are leaves. Later inputs win when overrides are allowed.
sets_:
if !(builtins.isBool allowOverrides) then
  builtins.throw "mergeAttrsRecursive: allowOverrides must be a boolean"
else if !(builtins.isList sets_) || !(builtins.all isMergeable_ sets_) then
  builtins.throw "mergeAttrsRecursive: expected a list of non-derivation attribute sets"
else
  let
    merged_ = merge_ [ ] (
      if allowOverrides then
        builtins.foldl' (reversed_: set_: [ set_ ] ++ reversed_) [ ] sets_
      else
        sets_
    );
  in
  builtins.seq merged_.checked merged_.value
