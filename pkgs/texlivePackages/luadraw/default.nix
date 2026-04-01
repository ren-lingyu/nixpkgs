{ stdenv, fetchFromGitHub, lib }:

stdenv.mkDerivation rec {
  
  pname = "luadraw";
  version = "2.7.0";
  src = fetchFromGitHub {
    owner = "pfradin";
    repo = "luadraw";
    rev = "a0713482ef87666fb59a788bae18ba58656e7163";
    fetchSubmodules = false;
    sha256 = "sha256-ERFPsPATl9bhq12vQfMIb5GpU2WXlyTlmw7dAKOir6k=";
  };
  
  dontBuild = true;
  dontStrip = true;
  
  outputs = [ "out" "tex" "texdoc" ];
  
  passthru = {
    tlType = "tex";
  };

  installPhase = lib.concatStringsSep "\n" [
    "runHook preInstall"
    ""
    "mkdir -p \$out"
    ""
    "mkdir -p \$tex/tex/latex/${pname}"
    "cp -r files/* \$tex/tex/latex/${pname}/"
    ""
    "mkdir -p \$texdoc/doc/latex/${pname}"
    "cp -r doc/* \$texdoc/doc/latex/${pname}/"
    ""
    "runHook postInstall"
  ];

  meta = with lib; {
    description = "LuaLaTeX package ${pname} version ${version}";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
  
}