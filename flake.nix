{
  description = "xin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix = {
      url = "github:nixos/nix/2.13.2";
      # Omitting `inputs.nixpkgs.follows = "nixpkgs";` on purpose
    };

  };

  outputs =
    { self
    , nixpkgs
    , fenix
    , naersk
    , nix
    , ...
    } @ inputs:
    let
      supportedSystems = [ "i686-linux" "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: (forSystem system f));

      forSystem = system: f: f rec {
        inherit system;
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
      };

      fenixToolchain = system: with fenix.packages.${system};
        combine ([
          stable.clippy
          stable.rustc
          stable.cargo
          stable.rustfmt
          stable.rust-src
        ] ++ nixpkgs.lib.optionals (system == "x86_64-linux") [
          targets.x86_64-unknown-linux-musl.stable.rust-std
        ] ++ nixpkgs.lib.optionals (system == "i686-linux") [
          targets.i686-unknown-linux-musl.stable.rust-std
        ] ++ nixpkgs.lib.optionals (system == "aarch64-linux") [
          targets.aarch64-unknown-linux-musl.stable.rust-std
        ]);
    in
    {
      devShells = forAllSystems ({ system, pkgs, ... }:
        let
          toolchain = fenixToolchain system;
        in
        {
          default = pkgs.mkShell {
            name = "xin-shell";

            RUST_SRC_PATH = "${toolchain}/lib/rustlib/src/rust/library";

            nativeBuildInputs = with pkgs; [ ];
            buildInputs = with pkgs; [
              toolchain
              rust-analyzer
              cargo-outdated
              cargo-audit
              nixpkgs-fmt
            ]
            ++ lib.optionals (pkgs.stdenv.isDarwin) (with pkgs; [ libiconv ]);
          };
        });
    };
}