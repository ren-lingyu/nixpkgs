{ }: final_: prev_: {
  a = {
    type = "derivation";
    marker = "a";
  };
  extraPackage = {
    type = "derivation";
    marker = "undeclared";
  };
  sequence = (prev_.sequence or "") + "a";
  applications = (prev_.applications or 0) + 1;
}
