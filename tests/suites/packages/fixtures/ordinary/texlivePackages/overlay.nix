{ }: final: prev: {
  explicitTex = true;
  texlivePackages = prev.texlivePackages // {
    fromParent = {
      type = "derivation";
      marker = "parent-local";
    };
  };
}
