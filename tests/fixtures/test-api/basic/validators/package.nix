{ writeText, shared }:
(writeText "test-api-validators" "${shared}:validators") // { testMarker = "${shared}:validators"; }
