{ config, pkgs, ... }:
{
  home.username = "neo";
  home.homeDirectory = "/Users/neo";
  home.stateVersion = "24.11";

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
  };

  programs.git = {
    enable = true;
    extraConfig = {
      gpg.program = "${pkgs.gnupg}/bin/gpg";
    };
  };

  programs.fish = {
    enable = true;
    shellInit = ''
      # Disable the welcome message
      set -g fish_greeting ""
    '';

    shellAliases = {
      hms = "home-manager switch";
      cd = "z";
      ls = "exa";
      l = "exa -l";
      la = "exa -l -a";
      gl = "git pull";
      gp = "git push";
      gst = "git status";
      gd = "git diff";
      gcb = "git checkout -b";
      gs = "git switch";
      gaa = "git add .";
      gmm = "git commit -m";
      gpsup = "git push --set-upstream origin $(git branch --show-current)";
    };

    interactiveShellInit = ''
      fish_add_path ~/.nix-profile/bin
      fish_add_path /nix/var/nix/profiles/default/bin
      fish_add_path /run/current-system/sw/bin
    
      if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      end
    
      if test -e ~/.nix-profile/etc/profile.d/hm-session-vars.fish
        source ~/.nix-profile/etc/profile.d/hm-session-vars.fish
      end
    
      set -gx GPG_TTY (tty)
    
      fish_vi_key_bindings
      set fish_cursor_default block
      set fish_cursor_insert line
      set fish_cursor_replace underscore
      set fish_cursor_replace_one underscore
      set fish_cursor_visual block

      if command -v zoxide >/dev/null
        zoxide init fish | source
      end
    
      if command -v direnv >/dev/null
        direnv hook fish | source
      end

      source ${pkgs.fzf}/share/fish/vendor_functions.d/fzf_key_bindings.fish

      if functions -q fzf_key_bindings

        # Set custom key bindings
        bind \eq fzf-file-widget  # Ctrl+F for file search
        bind \ew fzf-history-widget  # Ctrl+H for history search
        
        # Insert mode bindings (for vi mode)
        bind -M insert \eq fzf-file-widget
        bind -M insert \ew fzf-history-widget
      end
    '';
  };

  programs.fzf =
    {
      enable = true;
      enableFishIntegration = true;
    };

  nixpkgs.config = {
    allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
      "obsidian"
      "raycast"
    ];
  };

  home.packages = with pkgs; [
    ripgrep
    dust
    bat
    zoxide
    eza
    bottom
    neofetch
    neovim
    tldr
    aerospace
    sketchybar
    keepassxc
    gnupg
    vlc-bin
    obsidian
    raycast
    vscodium
    fzf
    direnv
    wget
    fish
    tree
    fd
  ];

  home.file = { };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
