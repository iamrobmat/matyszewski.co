#!/usr/bin/env bash

set -euo pipefail

output_dir="${1:-_site}"

if [[ -z "$output_dir" || "$output_dir" == "." || "$output_dir" == "/" ]]; then
  echo "Refusing to use an unsafe output directory: $output_dir" >&2
  exit 1
fi

rm -rf -- "$output_dir"
mkdir -p "$output_dir"

cp index.html styles.css analytics.js analytics-config.js CNAME .nojekyll "$output_dir/"
cp -R blog "$output_dir/blog"
cp -R uslugi "$output_dir/uslugi"
cp -R umow-rozmowe "$output_dir/umow-rozmowe"

node scripts/configure-analytics.mjs "$output_dir/analytics-config.js"

echo "Built static site in $output_dir."
