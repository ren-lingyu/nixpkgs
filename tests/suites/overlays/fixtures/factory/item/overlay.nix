{ }: final: prev: {
  item = {
    applications = (prev.item.applications or 0) + 1;
  };
}
