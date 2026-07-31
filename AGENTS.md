# matyszewski.co website agent

## Mission

Own the end-to-end development of Robert Matyszewski's personal website at
`matyszewski.co`. Treat this repository as a public, production-facing static
site and optimize for clear communication, fast loading, accessibility,
responsive behavior, and maintainable code.

The project-specific custom agent is `website_developer`, configured in
`.codex/agents/website-developer.toml`. Project runtime defaults live in
`.codex/config.toml`.

## Architecture

- The site is static HTML and CSS, published from the `main` branch with GitHub Pages.
- `index.html` and `styles.css` own the homepage.
- `blog/` contains the blog UI, generated post pages, post source files, and assets.
- Markdown post sources live in `blog/posts/`.
- `blog/posts/posts.json` is the blog index and metadata source.
- `scripts/generate-blog-preview.swift` regenerates public post pages and social preview assets.
- `CNAME` and `.nojekyll` are deployment-critical; change them only when the task requires it.

## Full-auto working mode

- For an unambiguous development request, inspect, implement, run relevant checks, and fix discovered regressions without asking for routine confirmation.
- Make reasonable, reversible assumptions when details are missing and state material assumptions in the handoff.
- Keep edits inside this repository. Preserve unrelated changes already present in the worktree.
- Prefer the existing dependency-free static architecture. Add a dependency or framework only when it materially improves the requested outcome.
- Use current official documentation when behavior depends on a changing browser, platform, GitHub Pages, or third-party API.
- Never expose secrets, personal data, unpublished credentials, or local-only files in public site artifacts.
- Do not commit, push, deploy, publish, purchase services, or mutate external accounts unless the user explicitly asks for that action.

## Implementation rules

- Use semantic HTML, progressive enhancement, and accessible interaction states.
- Maintain responsive behavior from narrow mobile screens through desktop widths.
- Preserve Polish copy and typography unless the user requests a language or editorial change.
- Reuse the existing visual system before introducing new colors, spacing rules, or components.
- Keep links valid and use descriptive alt text for meaningful images.
- When adding or changing a blog post, update its Markdown source and metadata, then regenerate derived pages and previews with:

```bash
swift scripts/generate-blog-preview.swift
```

- Do not hand-edit generated blog output when the source or generator should own the change.

## Verification

Choose checks proportionate to the change and complete all relevant ones:

1. Inspect `git diff --check` and the final diff.
2. Regenerate blog artifacts after blog-source or generator changes.
3. Serve the site locally when visible behavior changed:

   ```bash
   python3 -m http.server 8080
   ```

4. Check affected pages in a browser at mobile and desktop widths.
5. Verify navigation, external links, focus states, console errors, overflow, and missing assets for the changed surface.
6. Confirm generated files and public URLs remain consistent with `blog/posts/posts.json`.

## Handoff

Lead with the completed outcome. Summarize changed files, validation performed,
and any remaining limitation. Do not claim a check passed unless it was run.
