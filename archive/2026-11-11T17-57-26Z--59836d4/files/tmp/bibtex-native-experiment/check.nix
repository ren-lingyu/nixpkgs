{ runCommand, python3, texmacs, formatter }:
runCommand "bibtex-native-acceptance-experiment" { nativeBuildInputs = [ python3 ]; } ''
  mkdir -p "$out"
  python3 ${./run.py} \
    ${texmacs}/bin/texmacs ${formatter}/bin/treefmt \
    ${./probe.scm} ${./complex.bib} "$out"
''
