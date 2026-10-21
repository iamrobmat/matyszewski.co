#!/usr/bin/env bash

set -euo pipefail

output_dir="${1:-_site}"

if [[ -z "$output_dir" || "$output_dir" == "." || "$output_dir" == "/" ]]; then
  echo "Refusing to use an unsafe output directory: $output_dir" >&2
  exit 1
fi

node scripts/sync-navigation.mjs --check .

rm -rf -- "$output_dir"
mkdir -p "$output_dir"

cp index.html 404.html styles.css analytics.js analytics-config.js szkolenie.md robots.txt llms.txt "$output_dir/"
# GitHub Pages (CNAME, .nojekyll) and Cloudflare Workers static assets (_headers, _redirects).
cp CNAME .nojekyll _headers _redirects "$output_dir/"
cp -R blog "$output_dir/blog"
cp -R uslugi "$output_dir/uslugi"
cp -R szkolenia "$output_dir/szkolenia"
cp -R umow-rozmowe "$output_dir/umow-rozmowe"
cp -R ankieta "$output_dir/ankieta"
cp -R obrazy "$output_dir/obrazy"

node scripts/sync-navigation.mjs "$output_dir"
node scripts/configure-analytics.mjs "$output_dir/analytics-config.js"
node scripts/generate-sitemap.mjs "$output_dir"

echo "Built static site in $output_dir."
