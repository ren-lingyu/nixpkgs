{ writeText, shared }:
(writeText "test-api-alpha" "${shared}:alpha") // { testMarker = "${shared}:alpha"; }
