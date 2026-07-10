# Blog

This folder contains the editable Markdown blog.

## Add a post

1. Add a Markdown file to `posts/`, for example `posts/my-post.md`.
2. Add the post metadata to `posts/posts.json`.
3. Generate public post pages and social preview images.

```json
{
  "slug": "my-post",
  "title": "My Post",
  "description": "Short summary shown on the blog list.",
  "date": "2026-07-09",
  "file": "my-post.md"
}
```

```bash
swift scripts/generate-blog-preview.swift
```

Run that command from the repository root.

The public URL will be `/blog/my-post/`, and the post social image will be generated in
`assets/social/my-post.png`.

Supported Markdown: headings, paragraphs, lists, blockquotes, links, images, bold, italic, inline
code and fenced code blocks.
