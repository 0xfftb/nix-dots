{ pkgs ? import <nixpkgs> { } }:

let
  version = "1.0.0-beta.3";

  # Determine platform-specific values
  platform =
    if pkgs.stdenv.isDarwin then {
      name = if pkgs.stdenv.isAarch64 then "aarch64-apple-darwin" else "x86_64-apple-darwin";
      sha256 =
        if pkgs.stdenv.isAarch64 then
          "1sdpam42hrc6dzmfmy41hgpdbi7bbz03cmq0pws50xg2zr0bkgvb"
        else
          "13yr9hvmh269nvn4csbgwshagkirwhd4ilvyar6lcv051l5ks0jk";
    } else {
      name = if pkgs.stdenv.isAarch64 then "aarch64-unknown-linux-gnu" else "x86_64-unknown-linux-gnu";
      sha256 =
        if pkgs.stdenv.isAarch64 then
          "17x2mlaf5fa5hrqpvjvjqn81d905y1fsfd8pg0ji0nxs5ya2m09g"
        else
          "1q2nk9953ar4pfs9b5anf4q2hagffvwqc910vvbz2qdc2c487n1y";
    };

  url = "https://github.com/noir-lang/noir/releases/download/v${version}/noir-${platform.name}.tar.gz";
in
pkgs.stdenv.mkDerivation {
  pname = "noir";
  inherit version;

  src = pkgs.fetchurl {
    inherit url;
    sha256 = platform.sha256;
  };

  # For Linux, we need to patch the ELF binaries
  nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [
    pkgs.autoPatchelfHook
  ];

  buildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [
    pkgs.openssl
  ];

  # Skip build phase
  dontBuild = true;

  # Unpack the archive
  unpackPhase = ''
    mkdir -p unpacked
    tar -xzf $src -C unpacked
    cd unpacked
  '';

  # Install the binaries
  installPhase = ''
    mkdir -p $out/bin
    
    # Install binaries
    for bin in nargo noir-profiler noir-inspector; do
      if [ -f "$bin" ]; then
        install -Dm755 "$bin" "$out/bin/$bin"
        echo "Installed $bin"
      else
        echo "Warning: $bin not found"
      fi
    done
  '';

  meta = with pkgs.lib; {
    description = "Noir is a Domain Specific Language for SNARK proving systems";
    homepage = "https://noir-lang.org/";
    license = with licenses; [ mit asl20 ];
    maintainers = with maintainers; [ ];
    mainProgram = "nargo";
    platforms = platforms.unix;
  };
}
