{ lib, ... }: {
  options.packageAggregationNixos = lib.mkOption {
    type = lib.types.int;
    default = 42;
  };
}
