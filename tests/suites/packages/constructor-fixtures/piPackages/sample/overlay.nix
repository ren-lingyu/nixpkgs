{ extraArgs }: final: prev: {
  sample = {
    type = "derivation";
    marker = extraArgs.marker;
  };
}
