{ extraArgs }: final: prev: {
  added = {
    type = "derivation";
    marker = extraArgs.marker;
  };
}
