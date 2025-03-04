{
  description = "My development environments";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # Add rust-overlay for better Rust toolchain management
    rust-overlay.url = "github:oxalica/rust-overlay";
  };
  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Add the rust-overlay
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };

        # Use stable Rust with extensions
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
        };

        # Common shell hook to source root .zshrc
        commonShellHook = ''
          # Source root .zshrc if it exists and we're using zsh
          if [ -n "$ZSH_VERSION" ] && [ -f "$HOME/.zshrc" ]; then
            source "$HOME/.zshrc"
          fi
          
          # Add cargo bin to PATH
          export PATH="$HOME/.cargo/bin:$PATH"
          
          # Load .env file if it exists
          [ -f .env ] && source .env
        '';
      in
      {
        devShells = {
          # Web development environment
          web = pkgs.mkShell {
            buildInputs = with pkgs; [ nodejs yarn ];
            shellHook = ''
              ${commonShellHook}
              echo "Web development environment ready!"
            '';
          };

          # Blockchain development environment
          blockchain = pkgs.mkShell {
            buildInputs = with pkgs; [ nodejs yarn foundry ];
            shellHook = ''
              ${commonShellHook}
              echo "Blockchain development environment ready!"
              set +x
            '';
          };

          # Data science environment
          datascience = pkgs.mkShell {
            buildInputs = with pkgs; [ python3 python3Packages.numpy python3Packages.pandas ];
            shellHook = ''
              ${commonShellHook}
              echo "Data science environment ready!"
            '';
          };

          # Enhanced Rust development environment
          rust = pkgs.mkShell {
            buildInputs = with pkgs; [
              # Use the configured rust toolchain instead of just cargo
              rustToolchain

              # Common Rust development tools
              cargo-edit # For cargo add, cargo rm, etc.
              cargo-watch # For auto-recompilation during development
              cargo-expand # For macro expansion
              cargo-audit # For security audits
              cargo-tarpaulin # For code coverage
              cargo-outdated # Check for outdated dependencies

              # Build essentials
              pkg-config
              openssl
              openssl.dev

              # For cross-compilation if needed
              # gcc-arm-embedded
            ];

            shellHook = ''
              ${commonShellHook}
              
              # Set up library paths for common C dependencies
              export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig"
              export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
                pkgs.openssl
              ]}"
              
              # Configure Rust environment variables
              export RUST_BACKTRACE=1
              
              echo "Rust development environment ready!"
              echo "Rust version: $(rustc --version)"
              echo "Cargo version: $(cargo --version)"
              echo "Cargo binaries available in PATH"
            '';
          };
        };
      }
    );
}
