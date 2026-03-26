#!/bin/bash

# A script to update Vicinae theme using the current pywal colors.

# 1. Re-apply the current theme from cache to process templates.
#    This uses the colors from the last time 'wal' was run.
#    --theme: loads a theme file.
#    -t: processes templates in ~/.config/wal/templates/
#    -n: skips setting the terminal colors
#    -q: runs quietly
wal --theme ~/.cache/wal/colors.json -t -n -q

# 2. Move the generated theme to Vicinae's theme directory.
#    Pywal saves the processed template to ~/.cache/wal/vicinae.toml
mkdir -p ~/.local/share/vicinae/themes
mv -f ~/.cache/wal/vicinae.toml ~/.local/share/vicinae/themes/pywal.toml

# 3. Apply the new theme with Vicinae's CLI.
vicinae theme set pywal

echo "Vicinae theme 'pywal' has been updated from current wal colors and applied."