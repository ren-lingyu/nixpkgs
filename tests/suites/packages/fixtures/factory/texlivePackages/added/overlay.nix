final: prev: {
  added = {
    type = "derivation";
    applications = (prev.added.applications or 0) + 1;
  };
}
