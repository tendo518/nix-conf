# Model facts only. No endpoints, credentials, prices, or client-specific hints.
(builtins.fromJSON (builtins.readFile ./models-dev.json)) // import ./local.nix
