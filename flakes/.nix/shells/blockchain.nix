{ pkgs, unstable, commonShellHook }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs
    yarn
    foundry
    unstable.lintspec
    # Go for medusa dependencies
    go
    git
    circom
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
}
