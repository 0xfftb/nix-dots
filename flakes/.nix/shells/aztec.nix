{ pkgs, noir, rustToolchain, commonShellHook }:

let
  # Function to download Aztec tools
  downloadAztecTools = pkgs.writeShellScriptBin "download-aztec-tools" ''
    set -e
    
    # Create a directory for Aztec binaries
    AZTEC_BIN="$HOME/.aztec/bin"
    mkdir -p "$AZTEC_BIN"
    
    # Download and make executable
    download_tool() {
      local tool_name="$1"
      curl -fsSL "https://install.aztec.network/$tool_name" -o "$AZTEC_BIN/$tool_name"
      chmod +x "$AZTEC_BIN/$tool_name"
    }
    
    # Download specific tools
    download_tool ".aztec-run"
    download_tool "aztec"
    download_tool "aztec-up"
    download_tool "aztec-nargo"
    download_tool "aztec-wallet"
    
    # Pull Docker image
    docker pull aztecprotocol/aztec:latest
    
    echo "Aztec tools downloaded to $AZTEC_BIN"
  '';
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # Docker is required for the Aztec toolchain
    docker
    docker-compose
    # Additional dependencies
    socat
    curl
    git
    gnused
    bash
    nodejs
    yarn
    # Our download script
    downloadAztecTools
    # Noir language support
    noir
    # Common Rust development tools
    rustToolchain
    cargo-edit # For cargo add, cargo rm, etc.
    cargo-watch # For auto-recompilation during development
    cargo-expand # For macro expansion
    cargo-audit # For security audits
    cargo-outdated # Check for outdated dependencies
    # Build essentials
    pkg-config
    openssl
    openssl.dev
  ];
  shellHook = ''
    ${commonShellHook}
    
    # Ensure Aztec bin directory is in PATH
    export AZTEC_BIN="$HOME/.aztec/bin"
    export PATH="$AZTEC_BIN:$PATH"
    
    # Run download script if tools aren't already present
    if [ ! -x "$AZTEC_BIN/aztec" ]; then
      download-aztec-tools
    fi
    
    echo "Aztec toolchain is now available in this Nix shell."
  '';
}
