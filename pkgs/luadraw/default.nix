{ stdenv, fetchFromGitHub, lib, ... }:

stdenv.mkDerivation rec {
  
  pname = "luadraw";
  version = "2.7";
  src = fetchFromGitHub ({
    owner = "pfradin";
    repo = "luadraw";
    rev = "a0713482ef87666fb59a788bae18ba58656e7163";
    fetchSubmodules = false;
    sha256 = "sha256-ERFPsPATl9bhq12vQfMIb5GpU2WXlyTlmw7dAKOir6k=";
  });

  meta = {
    description = "Package ${pname} for LuaLaTeX version ${version}";
    platforms = lib.platforms.all;
  };

  installPhase = lib.concatStringsSep "\n" [
    "runHook preInstall"
    "mkdir -p \$out/tex/latex/${pname}/"
    "cp -r files/* \$out/tex/latex/${pname}/"
    "mkdir -p \$out/doc/latex/${pname}/"
    "cp -r doc/* \$out/doc/latex/${pname}/"
    "runHook postInstall"
  ];
  
}
