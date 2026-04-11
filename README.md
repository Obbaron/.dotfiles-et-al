# .dotfiles-et-al

Linux post-install setup with bootstrap script.

## Quick Start

Create and enter a directory for the bootstrap files:

```bash
mkdir .bstrap && cd .bstrap
```

Download the script using either `curl` or `wget`:

**curl:**
```bash
curl -fsL https://raw.githubusercontent.com/Obbaron/.bstrap/main/bstrap.sh -o bstrap.sh && chmod +x bstrap.sh
```

**wget:**
```bash
wget -qO bstrap.sh https://raw.githubusercontent.com/Obbaron/.bstrap/main/bstrap.sh && chmod +x bstrap.sh
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

## Configuration

All configuration is driven by `bstrap.yaml`. If not present it will be downloaded automatically from this repository.

### Packages

Packages are grouped by category and filtered by profile:

```yaml
packages:
  terminal:
    - name: btop
      profiles: [desktop, server]
```

If a package has a different name across package managers, use the optional `manager` block:

```yaml
    - name: python-yaml
      manager:
        pacman: python-yaml
        dnf: python3-pyyaml
        apt: python3-yaml
      profiles: [desktop, server, minimal]
```

### Directories

Directories to create, filtered by profile:

```yaml
directories:
  - path: ~/.config
    profiles: [desktop, server, minimal]
```

### Permissions

Set permissions on paths:

```yaml
permissions:
  - path: ~/.ssh
    mode: "700"
    profiles: [desktop, server, minimal]
```

### Services

Services to enable:

```yaml
services:
  - name: tailscaled
    profiles: [desktop, server]
```

### Dotfiles

Dotfiles to symlink, with source and destination paths:

```yaml
dotfiles:
  - src: dotfiles/.bashrc
    dst: ~/.bashrc
    profiles: [desktop, server, minimal]
```

### Profiles

The three built-in profiles are `minimal`, `server`, and `desktop`. Each entry in the YAML can belong to one or more profiles. To add a package to multiple profiles simply list them:

```yaml
profiles: [desktop, server, minimal]
```
