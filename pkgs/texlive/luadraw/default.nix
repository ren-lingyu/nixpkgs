{ stdenv, fetchFromGitHub, lib }:

stdenv.mkDerivation rec {
  
  pname = "luadraw";
  version = "2.8.0";
  src = fetchFromGitHub {
    owner = "pfradin";
    repo = "luadraw";
    rev = "4bbc37c8baadde6c25721ada659a6bd3953d971c";
    fetchSubmodules = false;
    sha256 = "sha256-JQJL89iGNyx8FLgIBXQVv0sxvpl1siRjZFmwJrnbGZg=";
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
