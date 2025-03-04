{ config, pkgs, ... }:
{
  home.username = "neo";
  home.homeDirectory = "/Users/neo";
  home.stateVersion = "24.11"; # Please read the comment before changing.

  nix = {
    package = pkgs.nix; # Add this line to specify the nix package
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
      ll = "ls -la";
      gl = "git pull";
      gp = "git push";
      gst = "git status";
      gd = "git diff";
      gcb = "git checkout -b";
      gs = "git switch";
      gaa = "git add .";
      gmm = "git commit -m";
    };

    interactiveShellInit = ''
      # Set up Nix paths - this is critical
      fish_add_path ~/.nix-profile/bin
    
      # Also add these paths to be safe
      fish_add_path /nix/var/nix/profiles/default/bin
      fish_add_path /run/current-system/sw/bin
    
      # Load Nix environment if available
      if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      end
    
      # Home Manager session variables
      if test -e ~/.nix-profile/etc/profile.d/hm-session-vars.fish
        source ~/.nix-profile/etc/profile.d/hm-session-vars.fish
      end
    
      # Rest of your Fish config...
      # Set GPG_TTY environment variable
      set -gx GPG_TTY (tty)
    
      # Vi key bindings
      fish_vi_key_bindings
    
      # Only initialize tools if they're in PATH
      if command -v zoxide >/dev/null
        zoxide init fish | source
      end
    
      if command -v direnv >/dev/null
        direnv hook fish | source
      end
    
      if command -v fzf >/dev/null && test -e ${pkgs.fzf}/share/fish/vendor_functions.d/fzf_key_bindings.fish
        source ${pkgs.fzf}/share/fish/vendor_functions.d/fzf_key_bindings.fish
      end
    '';
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
    EDITOR = "neovim";
  };

  programs.home-manager.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
