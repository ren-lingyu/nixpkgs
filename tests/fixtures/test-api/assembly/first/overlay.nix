{ }: final: prev: {
  existing = (final.writeText "test-api-first" "${prev.existing.testMarker}:first") // {
    testMarker = "${prev.existing.testMarker}:first";
  };
}
