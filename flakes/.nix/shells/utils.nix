{ pkgs }:

{
  # Common shell hook used across all environments
  commonShellHook = ''
    [ -f .env ] && source .env
  '';
}
