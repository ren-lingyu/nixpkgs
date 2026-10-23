final: prev: {
  dependent = final.callPackage (
    {
      writeText,
      existing,
      packages,
    }:
    (writeText "test-api-dependent" existing.testMarker)
    // {
      testMarker = existing.testMarker;
      packagesPath = packages.drvPath;
      explicitMarker = final.callPackage ({ existing }: existing.testMarker) { inherit (prev) existing; };
    }
  ) { };
}
