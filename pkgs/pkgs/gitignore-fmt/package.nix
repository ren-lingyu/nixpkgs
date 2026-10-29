{ writeShellApplication, coreutils }:
writeShellApplication {
  name = "gitignore-fmt";
  runtimeInputs = [ coreutils ];
  text = builtins.readFile ./gitignore-fmt.sh;
}
