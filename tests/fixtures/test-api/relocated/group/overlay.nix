{ descendantOverlay }: final: prev: {
  relocated = (final.lib.makeScope final.newScope (_: { })).overrideScope descendantOverlay;
}
