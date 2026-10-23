{ descendantOverlay }: final: prev: {
  group = (final.lib.makeScope final.newScope (_: { })).overrideScope descendantOverlay;
}
