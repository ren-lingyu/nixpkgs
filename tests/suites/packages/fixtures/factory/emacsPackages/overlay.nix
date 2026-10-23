{ descendantOverlay }: final: prev: {
  explicitEmacsFactory = true;
  emacsPackagesFor = emacs: (prev.emacsPackagesFor emacs).overrideScope descendantOverlay;
}
