import { createHash } from "node:crypto";
import { homedir } from "node:os";
import { basename, dirname, extname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(scriptDirectory, "..");
const defaultSource = join(homedir(), "dev", "prezki", "Eastmedia od czatu do agenta AI.html");
const defaultOutput = join(repositoryRoot, "public", "live", "deck", "index.html");

function option(name, fallback) {
  const index = process.argv.indexOf(name);
  return index === -1 ? fallback : process.argv[index + 1];
}

const sourcePath = resolve(option("--source", defaultSource));
const outputPath = resolve(option("--output", defaultOutput));
if (sourcePath === outputPath) throw new Error("Plik źródłowy i wynikowy muszą być różne.");

const outputDirectory = dirname(outputPath);
const imageDirectory = join(outputDirectory, "img");
const source = await readFile(sourcePath, "utf8");
const sourceBytes = Buffer.byteLength(source);
const dataUriPattern = /data:image\/(png|jpe?g|webp|gif|svg\+xml);base64,([A-Za-z0-9+/=\r\n]+)/g;
const matches = [...source.matchAll(dataUriPattern)];

await rm(imageDirectory, { recursive: true, force: true });
await mkdir(imageDirectory, { recursive: true });

let html = source;
const replacements = new Map();
let imageIndex = 0;

for (const match of matches) {
  const dataUri = match[0];
  if (replacements.has(dataUri)) continue;

  const bytes = Buffer.from(match[2].replace(/\s/g, ""), "base64");
  const mime = match[1].toLowerCase();
  const extension = mime === "jpeg" || mime === "jpg" ? "jpg" : mime === "svg+xml" ? "svg" : mime;
  const digest = createHash("sha256").update(bytes).digest("hex").slice(0, 12);
  const fileName = `image-${String(++imageIndex).padStart(2, "0")}-${digest}.${extension}`;
  await writeFile(join(imageDirectory, fileName), bytes);
  replacements.set(dataUri, `img/${fileName}`);
}

for (const [dataUri, relativePath] of replacements) {
  html = html.split(dataUri).join(relativePath);
}

html = html.replace(/[ \t]+$/gm, "");

html = html.replace(/(img-src\s+)([^;]*)(;)/i, (full, prefix, sources, suffix) => {
  if (/(?:^|\s)'self'(?:\s|$)/.test(sources)) return full;
  return `${prefix}'self' ${sources.trim()}${suffix}`;
});

if (!/img-src\s+[^;]*'self'/.test(html)) {
  throw new Error("Nie udało się dodać 'self' do dyrektywy CSP img-src.");
}

await mkdir(outputDirectory, { recursive: true });
await writeFile(outputPath, html);

const outputBytes = Buffer.byteLength(html);
const slideCount = (html.match(/class="[^"]*\bdeck-slide\b[^"]*"/g) ?? []).length;
console.log(JSON.stringify({
  source: basename(sourcePath),
  output: outputPath,
  sourceBytes,
  outputBytes,
  extractedImages: replacements.size,
  slideCount,
}, null, 2));
