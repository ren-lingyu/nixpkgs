{ }: final: prev: {
  check = (final.callPackage ./package.nix { }) // {
    applications = (prev.check.applications or 0) + 1;
  };
}
