final: prev: {
  sample = {
    type = "derivation";
    applications = (prev.sample.applications or 0) + 1;
  };
}
