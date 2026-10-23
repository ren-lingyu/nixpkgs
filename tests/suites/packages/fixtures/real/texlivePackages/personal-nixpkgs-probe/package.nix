{ stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "personal-nixpkgs-probe";
  version = "1";
  dontUnpack = true;
  dontBuild = true;
  outputs = [
    "out"
    "tex"
  ];
  passthru = {
    tlType = "run";
    tlDeps = _: [ ];
    testMarker = "added";
  };
  installPhase = ''
    mkdir -p "$out" "$tex/tex/latex/personal-nixpkgs-probe"
    echo '\\ProvidesPackage{personal-nixpkgs-probe}' > "$tex/tex/latex/personal-nixpkgs-probe/personal-nixpkgs-probe.sty"
  '';
}
