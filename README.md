# Mac Config

My macOS configuration managed by Nix-Darwin.

## Installation

Run the following command in your terminal, replacing `<config-name>` with one of the available configurations (e.g., `gg-mac`, `connie-mac`, `gg-linux`):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/chen-gz/mac-config/main/bootstrap.sh)" -- <config-name>
```

For example:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/chen-gz/mac-config/main/bootstrap.sh)" -- gg-mac
```
