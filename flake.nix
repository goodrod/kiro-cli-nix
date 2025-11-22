{
  description = "Kiro CLI - AI-powered coding assistant";

  # Inputs are other flakes this flake depends on
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  # Outputs define what this flake provides
  outputs = { self, nixpkgs, flake-utils }:
    # This helper makes the package available for multiple systems (x86_64-linux, aarch64-linux, etc.)
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Package version and metadata
        version = "1.20.0";

        # Define sources for different platforms
        # Each platform has its own URL and SHA256 hash for verification
        sources = {
          x86_64-linux = {
            url = "https://desktop-release.q.us-east-1.amazonaws.com/latest/1.20.0/kirocli-x86_64-linux.zip";
            sha256 = "9183663eba8930249c4b6bafa061ad87c0f8014fe3963bc3616056578aaa712d";
          };
          aarch64-linux = {
            url = "https://desktop-release.q.us-east-1.amazonaws.com/latest/1.20.0/kirocli-aarch64-linux.zip";
            sha256 = "112089854d5e07864dbe60a3a260560e8335fc698303549b33b2336780b38385";
          };
          x86_64-darwin = {
            url = "https://desktop-release.q.us-east-1.amazonaws.com/latest/1.20.0/Kiro%20CLI.dmg";
            sha256 = "2b5da6762caf32cc15dbf715f9a5f86df5f49f2d1a30da58b4a29dc4e01a1045";
          };
          aarch64-darwin = {
            # macOS DMG is universal binary, so we use the same for both architectures
            url = "https://desktop-release.q.us-east-1.amazonaws.com/latest/1.20.0/Kiro%20CLI.dmg";
            sha256 = "2b5da6762caf32cc15dbf715f9a5f86df5f49f2d1a30da58b4a29dc4e01a1045";
          };
        };

        # Get the source info for the current system
        src = sources.${system} or (throw "Unsupported system: ${system}");

      in {
        # The main package output
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "kiro-cli";
          inherit version;

          # Download the source
          src = pkgs.fetchurl {
            inherit (src) url sha256;
          };

          # Build-time dependencies
          nativeBuildInputs = with pkgs; [
            unzip
            autoPatchelfHook  # Automatically patches ELF binaries to work on NixOS
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            pkgs.undmg  # For extracting DMG files on macOS
          ];

          # Runtime dependencies - these are libraries the binary needs
          buildInputs = with pkgs; [
            stdenv.cc.cc.lib
            zlib
            openssl
          ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            # Linux-specific dependencies
            alsa-lib
            at-spi2-atk
            at-spi2-core
            atk
            cairo
            cups
            dbus
            expat
            fontconfig
            freetype
            gdk-pixbuf
            glib
            gtk3
            libdrm
            libnotify
            libsecret
            libuuid
            libxkbcommon
            mesa
            nspr
            nss
            pango
            systemd
            xorg.libX11
            xorg.libXcomposite
            xorg.libXdamage
            xorg.libXext
            xorg.libXfixes
            xorg.libXrandr
            xorg.libxcb
            xorg.libxshmfence
          ];

          # Don't strip the binary (sometimes causes issues)
          dontStrip = true;

          # Unpack phase - extract the archive
          unpackPhase = if pkgs.stdenv.isDarwin then ''
            undmg $src
          '' else ''
            unzip $src
          '';

          # Install phase - copy binaries to output
          installPhase = if pkgs.stdenv.isDarwin then ''
            mkdir -p $out/bin
            cp -r "Kiro CLI.app" $out/Applications/
            # Create symlink to the CLI binary
            ln -s "$out/Applications/Kiro CLI.app/Contents/MacOS/kiro-cli" $out/bin/kiro-cli
          '' else ''
            mkdir -p $out/bin

            # The zip contains a kirocli directory with binaries
            cd kirocli

            # Copy the main binaries
            cp kiro-cli $out/bin/
            cp kiro-cli-chat $out/bin/

            # Make them executable
            chmod +x $out/bin/kiro-cli
            chmod +x $out/bin/kiro-cli-chat

            # Copy any resources if they exist
            if [ -d resources ]; then
              mkdir -p $out/share/kiro-cli
              cp -r resources/* $out/share/kiro-cli/
            fi
          '';

          # Metadata for the package
          meta = with pkgs.lib; {
            description = "Kiro CLI - AI-powered coding assistant for the command line";
            homepage = "https://kiro.dev";
            license = licenses.unfree;  # Note: This is proprietary software
            platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
            maintainers = [ ];
          };
        };

        # Convenience: allow `nix run` to work
        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/kiro-cli";
        };
      }
    );
}
