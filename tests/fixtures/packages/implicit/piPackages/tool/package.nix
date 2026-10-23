{ sibling, parentMarker }: {
  type = "derivation";
  marker = "${parentMarker}:${sibling.marker}";
}
