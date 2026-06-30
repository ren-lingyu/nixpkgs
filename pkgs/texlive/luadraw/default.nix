{ stdenvNoCC, fetchFromGitHub, lib } : stdenvNoCC.mkDerivation rec {
  
  pname = "luadraw";
  version = "3.2";
  
  src = fetchFromGitHub {
    owner = "pfradin";
    repo = "luadraw";
    rev = "f4aec9ddf382e5c4b7d6629b01ac0b8639d7b0d6";
    fetchSubmodules = false;
    hash = "sha256-XuyuiGM1Kk0oh7rDahR/dqMIeWPyFEqx3vsYh7r8t+I=";
  };
  
  dontBuild = true;
  dontStrip = true;
  
  outputs = [ "out" "tex" "texdoc" ];
  
  passthru = {
    tlType = "run";
    tlDeps = ps_ : with ps_; [
      latex
      iftex
      luacode
      tools
      xkeyval
      pgf
    ];
  };
  
  installPhase = lib.concatStringsSep "\n" [
    "runHook preInstall"
    ""
    "mkdir -p \"$out\""
    ""
    "mkdir -p \"$tex/tex/lualatex/${pname}\""
    "cp -r files/* \"$tex/tex/lualatex/${pname}/\""
    ""
    "mkdir -p \"$texdoc/doc/lualatex/${pname}\""
    "cp -r doc/* \"$texdoc/doc/lualatex/${pname}/\""
    ""
    "runHook postInstall"
  ];
  
  meta = with lib; {
    description = "LuaLaTeX package ${pname} version ${version} for creating mathematical drawings";
    homepage = "https://github.com/pfradin/luadraw";
    license = licenses.lppl13c;
    platforms = platforms.all;
    maintainers = [ ];
  };
  
}
