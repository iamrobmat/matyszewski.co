import { readdir, stat } from "node:fs/promises";
import { resolve } from "node:path";

const root = resolve(process.argv[2] ?? "_site");
const maxAssetBytes = 25 * 1024 * 1024;
const oversized = [];

async function visit(directory) {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const path = resolve(directory, entry.name);
    if (entry.isDirectory()) {
      await visit(path);
    } else if (entry.isFile()) {
      const details = await stat(path);
      if (details.size > maxAssetBytes) {
        oversized.push({ path, size: details.size });
      }
    }
  }
}

await visit(root);

if (oversized.length > 0) {
  console.error(`Cloudflare static assets must not exceed ${maxAssetBytes} bytes:`);
  for (const asset of oversized) {
    console.error(`- ${asset.path} (${asset.size} bytes)`);
  }
  process.exit(1);
}

console.log(`Cloudflare asset size check passed for ${root}.`);
