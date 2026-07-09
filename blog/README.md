# Blog

This folder contains the editable Markdown blog.

## Add a post

1. Add a Markdown file to `posts/`, for example `posts/my-post.md`.
2. Add the post metadata to `posts/posts.json`.

```json
{
  "slug": "my-post",
  "title": "My Post",
  "description": "Short summary shown on the blog list.",
  "date": "2026-07-09",
  "file": "my-post.md"
}
```

The public URL will be `/blog/#my-post`.

Supported Markdown: headings, paragraphs, lists, blockquotes, links, images, bold, italic, inline
code and fenced code blocks.
