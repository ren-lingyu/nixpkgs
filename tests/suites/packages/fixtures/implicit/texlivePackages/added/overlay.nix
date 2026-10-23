{ }: final: prev: {
  added = {
    type = "derivation";
    marker = "added";
    applications = (prev.added.applications or 0) + 1;
  };
}
