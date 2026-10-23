{ descendantOverlay }: final: prev: {
  explicitFactory = true;
  factory = (final.lib.makeScope final.newScope (_: { })).overrideScope descendantOverlay;
}
