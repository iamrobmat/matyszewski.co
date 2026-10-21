import { execFileSync } from "node:child_process";
import { readdir, readFile, writeFile } from "node:fs/promises";
import { relative, resolve, sep } from "node:path";

const siteOrigin = "https://matyszewski.co";
const sourceRoot = resolve(".");
const outputRoot = resolve(process.argv[2] ?? "_site");

function git(...args) {
  try {
    return execFileSync("git", args, { cwd: sourceRoot, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
  } catch {
    return "";
  }
}

// CI often clones shallowly, which would date every file to the newest commit.
if (git("rev-parse", "--is-shallow-repository") === "true") {
  git("fetch", "--unshallow", "--quiet");
}

const historyIsComplete = git("rev-parse", "--is-shallow-repository") === "false";

function lastCommitDate(...paths) {
  return historyIsComplete ? git("log", "-1", "--format=%cs", "--", ...paths) : "";
}

async function collectIndexPages(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const entryPath = resolve(directory, entry.name);

    if (entry.isDirectory()) {
      files.push(...(await collectIndexPages(entryPath)));
    } else if (entry.name === "index.html") {
      files.push(entryPath);
    }
  }

  return files;
}

const posts = JSON.parse(await readFile(resolve(sourceRoot, "blog/posts/posts.json"), "utf8"));
const postsBySlug = new Map(posts.map((post) => [post.slug, post]));
const urls = [];

for (const filePath of await collectIndexPages(outputRoot)) {
  const html = await readFile(filePath, "utf8");

  if (/<meta\s+name="robots"\s+content="[^"]*noindex/i.test(html)) {
    continue;
  }

  const canonical = html.match(/<link\s+rel="canonical"\s+href="([^"]+)"/)?.[1];

  if (!canonical?.startsWith(`${siteOrigin}/`)) {
    continue;
  }

  const sourcePath = relative(outputRoot, filePath).split(sep).join("/");
  const slug = sourcePath.match(/^blog\/([^/]+)\/index\.html$/)?.[1];
  const post = slug ? postsBySlug.get(slug) : undefined;
  const sourceDates = post
    ? [post.date, lastCommitDate(`blog/posts/${post.file}`)]
    : [lastCommitDate(sourcePath)];
  const lastmod = sourceDates.filter(Boolean).sort().at(-1);

  urls.push({ loc: canonical, lastmod });
}

urls.sort((a, b) => a.loc.localeCompare(b.loc));

const entries = urls.map(({ loc, lastmod }) => {
  const lastmodLine = lastmod ? `\n    <lastmod>${lastmod}</lastmod>` : "";
  return `  <url>\n    <loc>${loc}</loc>${lastmodLine}\n  </url>`;
});

const sitemap = [
  '<?xml version="1.0" encoding="UTF-8"?>',
  '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
  ...entries,
  "</urlset>",
  "",
].join("\n");

await writeFile(resolve(outputRoot, "sitemap.xml"), sitemap, "utf8");
console.log(`Generated sitemap with ${urls.length} URLs${historyIsComplete ? "" : " (without git dates)"}.`);
