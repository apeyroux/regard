with import <nixpkgs> {};

let
drv = (haskellPackages.override {
  overrides = self: super: rec {
    http-client = self.callPackage ./nix/http-client.nix {};
    http-proxy = self.callPackage ./nix/http-proxy.nix {};
  };
}).callCabal2nix "regard" ./. {};
in if lib.inNixShell then drv.env.overrideAttrs (old: {
  buildInputs = old.buildInputs ++ [ haskellPackages.ghcid cabal-install ];
}) else drv
