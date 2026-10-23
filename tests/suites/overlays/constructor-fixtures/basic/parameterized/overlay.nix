{ extraArgs }: final: prev: {
  parameter = extraArgs.marker;
  parameterPath = extraArgs.source;
  parameterFunction = extraArgs.transform "value";
  automatic = final.callPackage ./package.nix { };
  explicit = final.callPackage ./package.nix { token = extraArgs.token; };
}
