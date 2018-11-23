let
  # https://vaibhavsagar.com/blog/2018/05/27/quick-easy-nixpkgs-pinning/
  fetcher = { owner?null, repo?null, rev, sha256
    , url ? "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz"
    }: builtins.fetchTarball {
      inherit url sha256;
    };
  nixpkgs = fetcher (builtins.fromJSON (builtins.readFile ../versions.json)).nixpkgs;
  inherit (import <nixpkgs> {}) lib writeScript;
  versions = lib.mapAttrs
     (_: fetcher)
       (builtins.fromJSON (builtins.readFile ../versions.json));

  updater = writeScript "updater.sh" ''
    #!/usr/bin/env bash
    ${./updater} versions.json nixpkgs pu
    ${./updater} versions.json nixpkgs-overlays pu
    ${./updater} versions.json krops master
    ${./updater} versions.json haskell-updates haskell-updates
    ${./updater} versions.json nixos-17.09 nixos-17.09
    ${./updater} versions.json nixos-18.03 nixos-18.03
    ${./updater} versions.json nixos-18.09 nixos-18.09
  '';
in versions // updater
