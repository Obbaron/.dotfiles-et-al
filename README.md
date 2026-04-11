# .dotfiles-et-al

A personal dotfiles and system bootstrap repository for Arch Linux and Fedora Asahi Remix.

## Bootstrap

The `bstrap` directory contains a post-install bootstrap script to set up a new system from scratch.

### Quick Start

Create and enter a directory for the bootstrap files:

```bash
mkdir bstrap && cd bstrap
```

Download the script using either `curl` or `wget`:

**curl:**
```bash
curl -fsL https://raw.githubusercontent.com/Obbaron/.dotfiles-et-al/main/bstrap/bstrap.sh -o bstrap.sh && chmod +x bstrap.sh
```

**wget:**
```bash
wget -qO bstrap.sh https://raw.githubusercontent.com/Obbaron/.dotfiles-et-al/main/bstrap/bstrap.sh && chmod +x bstrap.sh
```

Then run it:
```bash
./bstrap.sh
```

Or pass a profile directly:
```bash
./bstrap.sh desktop
./bstrap.sh server
./bstrap.sh minimal
```

### Configuration

All configuration is driven by `bstrap.yaml`. If not present it will be downloaded automatically from this repository.

#### Packages

Packages are grouped by category and filtered by profile:

```yaml
packages:
  terminal:
    - name: btop
      profiles: [desktop, server]
```

If a package has a different name across distros, use the optional `distro` block:

```yaml
    - name: python-yaml
      distro:
        arch: python-yaml
        fedora: python3-pyyaml
        ubuntu: python3-yaml
      profiles: [desktop, server, minimal]
```

#### Directories

Directories to create, filtered by profile:

```yaml
directories:
  - path: ~/.config
    profiles: [desktop, server, minimal]
```

#### Permissions

Set permissions on paths, filtered by profile:

```yaml
permissions:
  - path: ~/.ssh
    mode: "700"
    profiles: [desktop, server, minimal]
```

#### Services

Services to enable, filtered by profile:

```yaml
services:
  - name: ufw
    profiles: [desktop, server]
```

#### Dotfiles

Dotfiles to deploy, with source and destination paths, filtered by profile:

```yaml
dotfiles:
  - src: dotfiles/.bashrc
    dst: ~/.bashrc
    profiles: [desktop, server, minimal]
```

#### Profiles

The three built-in profiles are `minimal`, `server`, and `desktop`. Each entry in the YAML can belong to one or more profiles. To add a package to multiple profiles simply list them:

```yaml
profiles: [desktop, server, minimal]
```
