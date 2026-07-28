import { mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";

const measurementId = process.env.GOOGLE_ANALYTICS_ID?.trim() ?? "";
const outputPath = resolve(process.argv[2] ?? "analytics-config.js");

if (!/^G-[A-Z0-9]+$/.test(measurementId)) {
  console.error(
    "GOOGLE_ANALYTICS_ID must be set to a valid GA4 measurement ID such as G-ABC1234567.",
  );
  process.exit(1);
}

await mkdir(dirname(outputPath), { recursive: true });
await writeFile(
  outputPath,
  `window.MATYSZEWSKI_SITE_CONFIG = Object.freeze({\n  googleAnalyticsId: ${JSON.stringify(measurementId)},\n});\n`,
  "utf8",
);

console.log(`Generated Analytics configuration at ${outputPath}.`);
