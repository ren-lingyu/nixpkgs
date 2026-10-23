{ extraArgs }: final: prev: {
  probe = (final.pkgs.writeText "test-api-constructor" "constructor") // {
    constructorIsEmpty = extraArgs == { };
    scopeMarker = final.projectMarker;
    scopeExtraArgs = final.extraArgs.marker;
  };
}
