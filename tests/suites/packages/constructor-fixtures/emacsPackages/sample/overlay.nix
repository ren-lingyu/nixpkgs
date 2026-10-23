{ extraArgs }: final: prev: {
  sample = {
    type = "derivation";
    marker = "${prev.runtime.marker}:${extraArgs.marker}";
    applications = (prev.sample.applications or 0) + 1;
  };
}
