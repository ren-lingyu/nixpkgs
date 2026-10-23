{ writeText, shared }:
(writeText "test-api-beta" "${shared}:beta") // { testMarker = "${shared}:beta"; }
