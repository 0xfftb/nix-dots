{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    # Add medusa source
    medusa-src = {
      url = "github:crytic/medusa";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, rust-overlay, medusa-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Add the rust-overlay
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        # Create a reference to unstable packages
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
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

        # We'll use a custom script to build and install medusa instead of buildGoModule
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
          # Blockchain development environment with medusa
          blockchain = pkgs.mkShell {
            buildInputs = with pkgs; [
              nodejs
              yarn
              foundry
              unstable.lintspec
              # Add Go for medusa dependencies
              go
              git
              # Add Python and required packages for crytic-compile
              (pkgs.python3.withPackages (ps: with ps; [
                pip
                setuptools
                wheel
                # Add crytic-compile dependencies
                solc-select
              ]))
            ];
            shellHook = ''
                            ${commonShellHook}
              
                            # Add local binaries to PATH first
                            export PATH="$HOME/.local/bin:$PATH"
              
                            # Setup installation flags to track installation
                            VENV_DIR="$HOME/.local/share/medusa-venv"
                            INSTALL_FLAG_DIR="$HOME/.local/share/blockchain-env-flags"
                            CRYTIC_FLAG="$INSTALL_FLAG_DIR/crytic_installed"
                            MEDUSA_FLAG="$INSTALL_FLAG_DIR/medusa_installed"
              
                            # Create flag directory if it doesn't exist
                            mkdir -p "$INSTALL_FLAG_DIR"
              
                            # Install crytic-compile only if flag doesn't exist
                            if [ ! -f "$CRYTIC_FLAG" ]; then
                              echo "Installing crytic-compile (one-time setup)..."
                
                              # Create Python virtual environment
                              if [ ! -d "$VENV_DIR" ]; then
                                python3 -m venv "$VENV_DIR" >/dev/null 2>&1
                              fi
                
                              # Activate and install
                              source "$VENV_DIR/bin/activate"
                              pip install --quiet crytic-compile
                              deactivate
                
                              # Create wrapper script
                              mkdir -p "$HOME/.local/bin"
                              cat > "$HOME/.local/bin/crytic-compile" << 'EOF'
              #!/bin/sh
              VENV_DIR="$HOME/.local/share/medusa-venv"
              source "$VENV_DIR/bin/activate"
              "$VENV_DIR/bin/crytic-compile" "$@"
              result=$?
              deactivate
              exit $result
              EOF
                              chmod +x "$HOME/.local/bin/crytic-compile"
                
                              # Create flag file to mark installation as complete
                              touch "$CRYTIC_FLAG"
                              echo "Crytic-compile installed successfully"
                            fi
              
                            # Install medusa only if flag doesn't exist
                            if [ ! -f "$MEDUSA_FLAG" ]; then
                              echo "Building and installing medusa (one-time setup)..."
                              TEMP_DIR=$(mktemp -d)
                              git clone --quiet https://github.com/crytic/medusa "$TEMP_DIR"
                              cd "$TEMP_DIR"
                              go build -trimpath >/dev/null 2>&1
                              mkdir -p "$HOME/.local/bin"
                              cp medusa "$HOME/.local/bin/"
                              cd - > /dev/null 2>&1
                              rm -rf "$TEMP_DIR"
                
                              # Create flag file to mark installation as complete
                              touch "$MEDUSA_FLAG"
                              echo "Medusa installed to $HOME/.local/bin/medusa"
                            fi
              
                            # Ensure the Python virtual environment is in PATH
                            if [ -d "$VENV_DIR" ]; then
                              export PYTHONPATH="$VENV_DIR/lib/python3.*/site-packages:$PYTHONPATH"
                            fi
              
                            echo "Blockchain development environment ready!"
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
              cargo-tarpauline # For code coverage
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
