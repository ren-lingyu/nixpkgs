{ descendantOverlay }: final: prev: {
  explicitTexFactory = true;
  texlivePackages =
    (prev.lib.makeScope prev.newScope (_: prev.texlivePackages)).overrideScope
      descendantOverlay;
}
