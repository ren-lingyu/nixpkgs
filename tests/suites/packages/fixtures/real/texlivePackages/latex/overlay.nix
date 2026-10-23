final: prev: {
  latex = prev.latex.overrideAttrs (old: {
    name = "${old.name}-personal-nixpkgs-probe";
    passthru = (old.passthru or { }) // {
      testMarker = "replacement";
    };
  });
}
