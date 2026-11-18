#!/usr/bin/env bash

set -euo pipefail

output_dir="${1:-_site}"
deploy_target="${2:-github}"

if [[ -z "$output_dir" || "$output_dir" == "." || "$output_dir" == "/" ]]; then
  echo "Refusing to use an unsafe output directory: $output_dir" >&2
  exit 1
fi

if [[ "$deploy_target" != "github" && "$deploy_target" != "cloudflare" ]]; then
  echo "Unknown deployment target: $deploy_target (expected github or cloudflare)." >&2
  exit 1
fi

node scripts/sync-navigation.mjs --check .

rm -rf -- "$output_dir"
mkdir -p "$output_dir"

cp index.html 404.html styles.css navigation.js analytics.js analytics-config.js szkolenie.md szkolenie.pdf eastmedia.zip zarzadzanie-wiedza.pdf git-for-agents.pdf claude-design.pdf git-marketing.pdf robots.txt llms.txt "$output_dir/"

if [[ "$deploy_target" == "github" ]]; then
  cp kwartalnik-78.pdf CNAME .nojekyll "$output_dir/"
else
  cp _headers _redirects "$output_dir/"
  cp -R public/live "$output_dir/live"
fi
cp -R blog "$output_dir/blog"
cp -R uslugi "$output_dir/uslugi"
cp -R szkolenia "$output_dir/szkolenia"
cp -R szkolenie-pronar "$output_dir/szkolenie-pronar"
cp -R umow-rozmowe "$output_dir/umow-rozmowe"
cp -R ankieta "$output_dir/ankieta"
cp -R obrazy "$output_dir/obrazy"

node scripts/sync-navigation.mjs "$output_dir"
node scripts/configure-analytics.mjs "$output_dir/analytics-config.js"
node scripts/generate-sitemap.mjs "$output_dir"

if [[ "$deploy_target" == "cloudflare" ]]; then
  node scripts/check-cloudflare-assets.mjs "$output_dir"
fi

echo "Built $deploy_target static site in $output_dir."
