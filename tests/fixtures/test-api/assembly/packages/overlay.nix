{ }: final: prev: {
  packages = final.callPackage ({ writeText }: writeText "test-api-packages-name" "packages") { };
}
