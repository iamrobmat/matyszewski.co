import { readdir, readFile, writeFile } from "node:fs/promises";
import { relative, resolve, sep } from "node:path";

const navigationItems = Object.freeze([
  { id: "services", label: "Usługi", href: "/uslugi/" },
  { id: "work", label: "Co robię", href: "/#work" },
  { id: "projects", label: "Projekty", href: "/#projects" },
  { id: "blog", label: "Blog", href: "/blog/" },
  { id: "booking", label: "Umów rozmowę", href: "/umow-rozmowe/", className: "nav-cta" },
]);

const args = process.argv.slice(2);
const checkOnly = args.includes("--check");
const unknownFlags = args.filter((argument) => argument.startsWith("-") && argument !== "--check");

if (unknownFlags.length > 0) {
  console.error(`Unknown option: ${unknownFlags.join(", ")}`);
  process.exit(1);
}

const root = resolve(args.find((argument) => !argument.startsWith("-")) ?? ".");
const ignoredDirectories = new Set([".git", "_site", "node_modules"]);
const navigationPattern = /(^[ \t]*)<nav class="nav" aria-label="Główna nawigacja"[^>]*>[\s\S]*?<\/nav>/m;

function currentNavigationId(filePath) {
  const relativePath = relative(root, filePath).split(sep).join("/");

  if (relativePath === "uslugi/index.html") {
    return "services";
  }

  if (relativePath.startsWith("blog/")) {
    return "blog";
  }

  if (relativePath === "umow-rozmowe/index.html") {
    return "booking";
  }

  return "home";
}

function renderNavigation(indent, currentId) {
  const links = navigationItems.map((item) => {
    const classAttribute = item.className ? ` class="${item.className}"` : "";
    const currentAttribute = item.id === currentId ? ' aria-current="page"' : "";
    return `${indent}  <a${classAttribute} href="${item.href}"${currentAttribute}>${item.label}</a>`;
  });

  return [
    `${indent}<nav class="nav" aria-label="Główna nawigacja" data-nav-current="${currentId}">`,
    ...links,
    `${indent}</nav>`,
  ].join("\n");
}

async function collectHtmlFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    if (entry.isDirectory() && ignoredDirectories.has(entry.name)) {
      continue;
    }

    const entryPath = resolve(directory, entry.name);

    if (entry.isDirectory()) {
      files.push(...(await collectHtmlFiles(entryPath)));
    } else if (entry.isFile() && entry.name.endsWith(".html")) {
      files.push(entryPath);
    }
  }

  return files;
}

const htmlFiles = await collectHtmlFiles(root);
const outdatedFiles = [];
let navigationCount = 0;

for (const filePath of htmlFiles) {
  const html = await readFile(filePath, "utf8");
  const match = html.match(navigationPattern);

  if (!match) {
    continue;
  }

  navigationCount += 1;
  const expectedNavigation = renderNavigation(match[1], currentNavigationId(filePath));
  const updatedHtml = html.replace(navigationPattern, expectedNavigation);

  if (updatedHtml === html) {
    continue;
  }

  const displayPath = relative(root, filePath) || filePath;
  outdatedFiles.push(displayPath);

  if (!checkOnly) {
    await writeFile(filePath, updatedHtml, "utf8");
  }
}

if (navigationCount === 0) {
  console.error(`No site navigation found in ${root}.`);
  process.exit(1);
}

if (checkOnly && outdatedFiles.length > 0) {
  console.error("Navigation is out of sync in:");
  for (const filePath of outdatedFiles) {
    console.error(`- ${filePath}`);
  }
  console.error("Run: node scripts/sync-navigation.mjs");
  process.exit(1);
}

if (checkOnly) {
  console.log(`Navigation is consistent across ${navigationCount} pages.`);
} else {
  console.log(`Synchronized navigation across ${navigationCount} pages (${outdatedFiles.length} updated).`);
}
