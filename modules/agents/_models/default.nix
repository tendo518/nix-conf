# Subscribed provider facts plus explicit local connection facts.
(builtins.fromJSON (builtins.readFile ./models-dev.json))
// {
  local = import ./local.nix;
}
