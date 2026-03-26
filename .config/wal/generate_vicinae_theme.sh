#!/bin/bash
echo "Script ran at $(date)" >> ~/vicinae_debug.log

# Source the pywal colors
source "$HOME/.cache/wal/colors.sh"

# Path to the template and output file
template="$HOME/.config/wal/templates/vicinae.toml"
output_dir="$HOME/.local/share/vincinae/themes"
output_file="$output_dir/pywal.toml"

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Read the template and replace the placeholders
# Using a temporary file to avoid issues with sed's in-place editing
tmp_file=$(mktemp)
cp "$template" "$tmp_file"

sed -i "s|{background}|$background|g" "$tmp_file"
sed -i "s|{foreground}|$foreground|g" "$tmp_file"
sed -i "s|{color0}|$color0|g" "$tmp_file"
sed -i "s|{color1}|$color1|g" "$tmp_file"
sed -i "s|{color2}|$color2|g" "$tmp_file"
sed -i "s|{color3}|$color3|g" "$tmp_file"
sed -i "s|{color4}|$color4|g" "$tmp_file"
sed -i "s|{color5}|$color5|g" "$tmp_file"
sed -i "s|{color6}|$color6|g" "$tmp_file"
sed -i "s|{color7}|$color7|g" "$tmp_file"
sed -i "s|{color8}|$color8|g" "$tmp_file"
sed -i "s|{color9}|$color9|g" "$tmp_file"
sed -i "s|{color10}|$color10|g" "$tmp_file"
sed -i "s|{color11}|$color11|g" "$tmp_file"
sed -i "s|{color12}|$color12|g" "$tmp_file"
sed -i "s|{color13}|$color13|g" "$tmp_file"
sed -i "s|{color14}|$color14|g" "$tmp_file"
sed -i "s|{color15}|$color15|g" "$tmp_file"

# Move the processed file to the final destination
mv "$tmp_file" "$output_file"

echo "Vincinae theme generated at $output_file"
