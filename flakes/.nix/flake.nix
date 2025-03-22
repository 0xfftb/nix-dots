{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    medusa-src = {
      url = "github:crytic/medusa";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, rust-overlay, medusa-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];

        pkgs = import nixpkgs { inherit system overlays; };

        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };

        # Import the Noir package from noir.nix
        noir = import ./packages/noir.nix { inherit pkgs; };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
        };

        # Import utilities
        utils = import ./shells/utils.nix { inherit pkgs; };
        inherit (utils) commonShellHook;

        # Import shell modules
        webShell = import ./shells/web.nix { inherit pkgs commonShellHook; };
        tsShell = import ./shells/ts.nix { inherit pkgs commonShellHook; };
        blockchainShell = import ./shells/blockchain.nix { inherit pkgs unstable commonShellHook; };
        rustShell = import ./shells/rust.nix { inherit pkgs rustToolchain commonShellHook; };
        aztecShell = import ./shells/aztec.nix { inherit pkgs noir rustToolchain commonShellHook; };

      in
      {
        devShells = {
          web = webShell;
          ts = tsShell;
          blockchain = blockchainShell;
          rust = rustShell;
          aztec = aztecShell;
        };
      }
    );
}
