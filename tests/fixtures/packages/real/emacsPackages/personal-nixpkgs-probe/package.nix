{ trivialBuild, writeText }:
trivialBuild {
  pname = "personal-nixpkgs-probe";
  version = "1";
  src = writeText "personal-nixpkgs-probe.el" "(provide 'personal-nixpkgs-probe)";
}
