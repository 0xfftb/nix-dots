{ pkgs, commonShellHook }:

pkgs.mkShell {
  buildInputs = with pkgs; [ bun ];
  shellHook = ''
    ${commonShellHook}
    echo "Typescript development environment ready!"
  '';
}
