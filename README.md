# matyszewski.co

Public static website for Robert Matyszewski.

This repository is published with GitHub Pages from the `main` branch and uses `matyszewski.co`
as its custom domain.

## Structure

- `index.html` - static one-page website with a link to the blog
- `styles.css` - responsive visual system
- `blog/` - self-contained Markdown blog
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

The public URL will be `/blog/#my-post`. The blog is rendered in the browser and supports a small
Markdown subset: headings, paragraphs, lists, blockquotes, links, images, bold, italic, inline code
and fenced code blocks.

DNS for `matyszewski.co` must point to GitHub Pages for the custom domain to resolve.

## Local preview

```bash
python3 -m http.server 8080
```

Then open `http://localhost:8080`.
