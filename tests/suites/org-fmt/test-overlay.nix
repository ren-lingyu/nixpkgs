{ }: final: prev: {
  org-fmt = final.callPackage ./check.nix {
    org-fmt = prev.org-fmt;
    documents = prev.org-fmt-documents;
  };
}
