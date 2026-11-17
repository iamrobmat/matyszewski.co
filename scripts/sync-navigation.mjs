import { readdir, readFile, writeFile } from "node:fs/promises";
import { relative, resolve, sep } from "node:path";

const navigationItems = Object.freeze([
  { id: "services", label: "Usługi", href: "/uslugi/" },
  { id: "work", label: "Co robię", href: "/#work" },
  { id: "projects", label: "Projekty", href: "/#projects" },
  { id: "blog", label: "Blog", href: "/blog/" },
  { id: "booking", label: "Umów rozmowę", href: "/umow-rozmowe/", className: "nav-cta" },
]);

const trainingItems = Object.freeze([
  { label: "Wszystkie szkolenia", href: "/szkolenia/" },
  { label: "Od czatu do agenta", href: "/szkolenia/od-czatu-do-agenta/" },
  {
    label: "Zarządzanie wiedzą z agentami AI",
    href: "/szkolenia/zarzadzanie-wiedza-z-agentami-ai/",
  },
  { label: "Git w pracy z agentami", href: "/szkolenia/git-w-pracy-z-agentami/" },
  { label: "Claude Design", href: "/szkolenia/claude-design/" },
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
const navigationPattern = /(^[ \t]*)?<nav class="nav" aria-label="Główna nawigacja"[^>]*>[\s\S]*?<\/nav>(?:\s*<script src="\/navigation\.js" defer><\/script>)?/m;

function currentNavigationId(filePath) {
  const relativePath = relative(root, filePath).split(sep).join("/");

  if (relativePath.startsWith("uslugi/")) {
    return "services";
  }

  if (relativePath.startsWith("szkolenia/")) {
    return "training";
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
  const renderLink = (item) => {
    const classAttribute = item.className ? ` class="${item.className}"` : "";
    const currentAttribute = item.id === currentId ? ' aria-current="page"' : "";
    return `${indent}  <a${classAttribute} href="${item.href}"${currentAttribute}>${item.label}</a>`;
  };

  const [servicesItem, ...remainingItems] = navigationItems;
  const trainingCurrentAttribute = currentId === "training" ? ' aria-current="page"' : "";
  const trainingLinks = trainingItems
    .map((item) => `${indent}      <a href="${item.href}">${item.label}</a>`)
    .join("\n");

  return [
    `${indent}<nav class="nav" aria-label="Główna nawigacja" data-nav-current="${currentId}">`,
    renderLink(servicesItem),
    `${indent}  <details class="nav-dropdown">`,
    `${indent}    <summary${trainingCurrentAttribute}>Szkolenia</summary>`,
    `${indent}    <div class="nav-dropdown-menu">`,
    trainingLinks,
    `${indent}    </div>`,
    `${indent}  </details>`,
    ...remainingItems.map(renderLink),
    `${indent}</nav>`,
    `${indent}<script src="/navigation.js" defer></script>`,
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
  const expectedNavigation = renderNavigation(match[1] ?? "", currentNavigationId(filePath));
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
