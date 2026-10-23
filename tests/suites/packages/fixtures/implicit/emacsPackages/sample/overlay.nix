final: prev: {
  sample = {
    type = "derivation";
    marker = "${prev.runtime.marker}:sample";
    applications = (prev.sample.applications or 0) + 1;
  };
}
