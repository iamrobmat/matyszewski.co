# matyszewski.co

Public static website for Robert Matyszewski.

This repository is published with GitHub Pages from the `main` branch and uses `matyszewski.co`
as its custom domain.

## Structure

- `index.html` - static one-page website with a link to the blog
- `styles.css` - responsive visual system
- `blog/` - self-contained Markdown blog
- `drafts/blog/` - unpublished source drafts and their private working assets
- `kurs/` - unpublished course-area prototype; it is not copied to deployment artifacts
- `scripts/sync-navigation.mjs` - the single source of truth for site navigation
- `CNAME` - configures the `matyszewski.co` custom domain
- `.nojekyll` - disables Jekyll processing for GitHub Pages

## Blog posts

Blog files live in `blog/` so they are easy to edit independently from the homepage.

Add a Markdown file to `blog/posts/`, then add its metadata to `blog/posts/posts.json`:

```json
{
  "slug": "my-post",
  "title": "My Post",
  "description": "Short summary shown on the blog list.",
  "date": "2026-07-09",
  "file": "my-post.md"
}
```

Generate the public post pages and social preview images:

```bash
swift scripts/generate-blog-preview.swift
```

The public URL will be `/blog/my-post/`. The generated pages support a small Markdown subset:
headings, paragraphs, lists, blockquotes, links, images, bold, italic, inline code and fenced code
blocks.

## Navigation

All page headers are generated from the navigation definition in
`scripts/sync-navigation.mjs`. After changing navigation labels or destinations, synchronize the
source pages with:

```bash
node scripts/sync-navigation.mjs
```

The blog generator runs this synchronization automatically, and the production build verifies that
committed pages are current before creating the deployment artifact.

DNS for `matyszewski.co` must point to GitHub Pages for the custom domain to resolve.

## Deployment targets

GitHub Pages remains the production host for `matyszewski.co`. Cloudflare Workers serves a
non-indexable technical mirror at its `workers.dev` address. Both deployments build from `main`.
See `docs/hosting.md` for the operational setup and intentional differences.

Build GitHub Pages, including `CNAME`, `.nojekyll` and all public PDFs:

```bash
GOOGLE_ANALYTICS_ID=G-ABC1234567 bash scripts/build-site.sh _site github
```

Build the Cloudflare mirror, including `_headers` and `_redirects` but excluding the 58 MB
`kwartalnik-78.pdf`, which exceeds the Workers static-asset limit:

```bash
GOOGLE_ANALYTICS_ID=G-ABC1234567 bash scripts/build-site.sh _site cloudflare
```

The default target is `github`. Every Cloudflare build also checks that no generated asset exceeds
25 MiB. Neither target copies `drafts/` or `kurs/`.

## Google Analytics

Analytics uses consent-gated Google tag loading. The tag is not requested until a visitor accepts
analytics, while ad storage, ad user data and ad personalisation remain disabled.

The GA4 measurement ID is injected at build time and is not stored in the source configuration:

```bash
GOOGLE_ANALYTICS_ID=G-ABC1234567 bash scripts/build-site.sh _site github
```

For production, create a GitHub Actions repository variable named `GOOGLE_ANALYTICS_ID` and set
the Pages publishing source to GitHub Actions. The workflow in `.github/workflows/pages.yml` builds
the `_site` artifact and deploys it.

## Local preview

```bash
python3 -m http.server 8080
```

Then open `http://localhost:8080`.
