{ }: final: prev: {
  existing = (final.writeText "test-api-second" "${prev.existing.testMarker}:second") // {
    testMarker = "${prev.existing.testMarker}:second";
  };
}
