# Kiro CLI Nix Package

This is a Nix flake that packages [Kiro CLI](https://kiro.dev), an AI-powered coding assistant for the command line.

## What is a Nix Flake?

A Nix flake is a reproducible, declarative way to package software. This flake:
- Downloads the official Kiro CLI binaries
- Verifies them with SHA256 checksums
- Packages them for easy installation on NixOS or with Nix package manager
- Handles all dependencies automatically

## Prerequisites

1. **Nix with Flakes enabled**

   Add this to your `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`:
   ```
   experimental-features = nix-command flakes
   ```

2. **Unfree packages allowed** (Kiro CLI is proprietary)

   Add this to your NixOS configuration or `~/.config/nixpkgs/config.nix`:
   ```nix
   { allowUnfree = true; }
   ```

## Usage

### Option 1: Try without installing

```bash
nix run github:yourusername/kiro-cli-nix
```

Or locally:
```bash
nix run .#
```

### Option 2: Install temporarily (in a shell)

```bash
nix shell github:yourusername/kiro-cli-nix
kiro-cli --help
```

### Option 3: Install in your NixOS configuration

Add this flake as an input to your system flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    kiro-cli.url = "path:/home/mackieg/kiro-cli-nix";  # or git+file:///home/mackieg/kiro-cli-nix
  };

  outputs = { self, nixpkgs, kiro-cli, ... }: {
    nixosConfigurations.yourhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.config.allowUnfree = true;

          environment.systemPackages = [
            kiro-cli.packages.x86_64-linux.default
          ];
        }
      ];
    };
  };
}
```

### Option 4: Install in Home Manager

```nix
{
  inputs = {
    kiro-cli.url = "path:/home/mackieg/kiro-cli-nix";
  };

  outputs = { self, nixpkgs, kiro-cli, ... }: {
    homeConfigurations.youruser = {
      home.packages = [
        kiro-cli.packages.x86_64-linux.default
      ];
    };
  };
}
```

### Option 5: Add to your user profile

```bash
nix profile install .#
```

## Testing the Build

Before using it, test that it builds:

```bash
# Check the flake is valid
nix flake check

# Build it (without installing)
nix build

# The result will be in ./result/bin/kiro-cli
./result/bin/kiro-cli --version
```

## Included Binaries

- `kiro-cli` - Main CLI tool
- `kiro-cli-chat` - Chat interface

## Package Information

- **Version**: 1.20.0
- **Platforms**: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin
- **License**: Proprietary (Amazon Software License)
- **Homepage**: https://kiro.dev

## Updating

To update to a new version:

1. Check the latest version at https://desktop-release.q.us-east-1.amazonaws.com/latest/manifest.json
2. Update the `version` variable in `flake.nix`
3. Update the URLs and SHA256 hashes in the `sources` attribute set
4. Run `nix flake lock --update-input nixpkgs` to update dependencies

## Troubleshooting

### Permission denied on /nix/store

Run Nix commands with appropriate permissions. On NixOS, this should work by default. On non-NixOS systems, you may need to be in the `nix-users` group.

### Unfree package error

Make sure you've allowed unfree packages (see Prerequisites above).

### Binary not found after install

Make sure `~/.nix-profile/bin` is in your PATH.

## Alternative: Use the Official Install Script

If you prefer the official installation method:

```bash
curl -fsSL https://cli.kiro.dev/install | bash
```

## Directory Structure

```
kiro-cli-nix/
├── flake.nix          # Main package definition
├── flake.lock         # Lock file (auto-generated)
└── README.md          # This file
```

## Contributing

This is a simple packaging of upstream binaries. For issues with Kiro CLI itself, visit https://kiro.dev.

For packaging improvements, feel free to modify the flake!
