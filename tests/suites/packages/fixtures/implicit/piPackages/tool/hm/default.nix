{ lib, ... }: {
  options.packageAggregationHome = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };
}
