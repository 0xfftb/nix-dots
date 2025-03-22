{ pkgs, commonShellHook }:

pkgs.mkShell {
  buildInputs = with pkgs; [ nodejs yarn ];
  shellHook = ''
    ${commonShellHook}
    echo "Web development environment ready!"
  '';
}
