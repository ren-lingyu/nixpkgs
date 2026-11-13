{ }: final: prev: {
  second = final.callPackage (
    {
      lib,
      first,
      bundle,
    }:
    lib.mergeAttrsList [
      first
      { dependencyMarker = bundle.nested.check.testMarker; }
    ]
  ) { };
}
