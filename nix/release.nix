with import <nixpkgs> {};

let

  # cachix use static-haskell-nix 
  static-pkgs = import (fetchTarball https://github.com/NixOS/nixpkgs/archive/88ae8f7d.tar.gz) {};
  regard = (haskellPackages.override {
    overrides = self: super: rec {
      http-client = self.callPackage ./http-client.nix {};
      http-proxy = self.callPackage ./http-proxy.nix {};
    };
  }).callCabal2nix "regard" ../. {};
  vmDebian = pkgs.vmTools.diskImageFuns.debian8x86_64 {};

in rec {
  docker-img = dockerTools.buildImage {
    name = "regard";
    tag = "latest";
    created = "now";
    contents = [ regard ];
    config = {
      EntryPoint = ["regard"];
      Cmd = ["regard"];
   };
  };

  static-bin = pkgsMusl.callPackage ((fetchTarball https://github.com/apeyroux/static-haskell-nix/archive/apeyroux.tar.gz) + "/survey") {normalPkgs=static-pkgs; };

  src-tar = releaseTools.sourceTarball {
    buildInputs = [ cabal-install ];
    distPhase = ''
    cabal sdist
    mkdir -p $out/tarballs/
    cp dist/${regard.name}.tar.gz $out/tarballs/
    '';
    src = ./.;
  };

  # NIX_PATH=nixpkgs=https://github.com/NixOS/nixpkgs/archive/88ae8f7d.tar.gz  nix-build release.nix -A bin-tar
  bin-tar = releaseTools.binaryTarball {
    doCheck = false;
    showBuildStats = false;
    buildPhase = "";
    installPhase = ''
    releaseName=${regard.name}
    ${coreutils}/bin/install --target-directory "$TMPDIR/inst/bin" -D ${static-bin.haskellPackages.regard}/bin/regard
    '';
    src = ./.;
  };

  # NIX_PATH=nixpkgs=https://github.com/NixOS/nixpkgs/archive/88ae8f7d.tar.gz nix-build release.nix -A deb --out-link deb
  deb = releaseTools.debBuild {
    diskImage = vmDebian;
    name = regard.name;
    debMaintainer = "Alexandre Peyroux";
    meta.description = regard.name;
    doCheck = false;
    doInstallCheck = false;
    showBuildStats = false;
    preInstall = ''
cat <<EOT >> Makefile
install:
	cp ${static-bin.haskellPackages.regard}/bin/regard /usr/local/bin
EOT
    '';
    src = src-tar;
  };

 }
