final: prev: {
  item = {
    marker = prev.seed or "generic";
    applications = (prev.item.applications or 0) + 1;
  };
}
