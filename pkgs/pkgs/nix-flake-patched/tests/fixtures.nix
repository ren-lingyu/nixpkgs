{
  # Only input structure is borrowed from the reference repositories.
  # Cross-source inputs become local archives; every /pkgs edge stays relative.
  topology = {
    upstream.inputs = { };
    "personal/pkgs".inputs.nixpkgs = "upstream";
    personal = {
      inputs = {
        nixpkgs = "upstream";
        local-nixpkgs = "personal/pkgs";
      };
      relative = [ "local-nixpkgs" ];
      follows."local-nixpkgs.nixpkgs" = "nixpkgs";
    };
    org-texmacs = {
      inputs = {
        nixpkgs = "upstream";
        personal-nixpkgs = "personal";
      };
      follows."personal-nixpkgs.nixpkgs" = "nixpkgs";
    };
    emarccs = {
      inputs = {
        nixpkgs = "upstream";
        personal-nixpkgs = "personal";
        org-texmacs = "org-texmacs";
      };
      follows = {
        "personal-nixpkgs.nixpkgs" = "nixpkgs";
        "org-texmacs.nixpkgs" = "nixpkgs";
      };
    };
    git-agent-workflow = {
      inputs = {
        nixpkgs = "upstream";
        personal-nixpkgs = "personal";
      };
      follows."personal-nixpkgs.nixpkgs" = "nixpkgs";
    };
    "nixos/pkgs" = {
      inputs = {
        nixpkgs = "upstream";
        personal-nixpkgs = "personal";
        emarccs = "emarccs";
        git-agent-workflow = "git-agent-workflow";
      };
      follows = {
        "personal-nixpkgs.nixpkgs" = "nixpkgs";
        "emarccs.nixpkgs" = "nixpkgs";
        "git-agent-workflow.nixpkgs" = "nixpkgs";
      };
    };
    nixos = {
      inputs = {
        nixpkgs = "upstream";
        personal-nixpkgs = "personal";
        local-nixpkgs = "nixos/pkgs";
      };
      relative = [ "local-nixpkgs" ];
      follows."personal-nixpkgs.nixpkgs" = "nixpkgs";
    };
  };
}
