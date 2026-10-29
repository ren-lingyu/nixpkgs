{
  writeShellApplication,
  coreutils,
  diffutils,
}:
writeShellApplication {
  name = "gitignore-fmt";
  runtimeInputs = [
    coreutils
    diffutils
  ];
  text = builtins.readFile ./gitignore-fmt.sh;
}
