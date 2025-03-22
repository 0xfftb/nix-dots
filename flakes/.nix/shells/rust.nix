{ pkgs, rustToolchain, commonShellHook }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Use the configured rust toolchain instead of just cargo
    rustToolchain
    # Common Rust development tools
    cargo-edit # For cargo add, cargo rm, etc.
    cargo-watch # For auto-recompilation during development
    cargo-expand # For macro expansion
    cargo-audit # For security audits
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

    export PATH=$HOME/.cargo/bin:$PATH
    
    # Configure Rust environment variables
    export RUST_BACKTRACE=1
    
    echo "Rust development environment ready!"
    echo "Rust version: $(rustc --version)"
    echo "Cargo version: $(cargo --version)"
    echo "Cargo binaries available in PATH"
  '';
}
