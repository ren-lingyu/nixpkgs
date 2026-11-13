{ }: final: prev: {
  # These members are useful in the scope, but are not registered checks.
  dependency = prev.first;
  helper = value_: value_;
  poison = throw "unselected overlay member must stay lazy";
  self = final;
  empty.added = prev.first;
  first = final.callPackage (
    { lib }:
    lib.mergeAttrsList [
      prev.first
      { testMarker = "overridden"; }
    ]
  ) { };
}
