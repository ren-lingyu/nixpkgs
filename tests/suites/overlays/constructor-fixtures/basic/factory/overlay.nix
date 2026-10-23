{ extraArgs, descendantOverlay }: final: prev: {
  factory =
    (final.lib.makeScope final.newScope (_: {
      constructorMarker = extraArgs.marker;
    })).overrideScope
      descendantOverlay;
}
