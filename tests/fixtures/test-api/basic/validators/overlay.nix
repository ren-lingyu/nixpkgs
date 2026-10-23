final: prev: {
  validators = (final.callPackage ./package.nix { }) // {
    scopeObservation = {
      helpersAvailable = final ? callPackage && final ? newScope;
      helperIsFunction = builtins.isFunction final.helpers;
      hiddenValueIsDerivation = final.lib.isDerivation final.values.nested;
      emacsMarker = final.emacsPackages.sample.marker;
      texMarker = final.texlivePackages.sample.marker;
      noPackageFactories = !(final ? emacsPackagesFor) && !(final ? texlive);
      inherit (final) unmapped;
    };
  };
}
