{ }: final_: prev_: {
  z = {
    type = "derivation";
    marker = "z";
  };
  sequence = (prev_.sequence or "") + "z";
  applications = (prev_.applications or 0) + 1;
}
