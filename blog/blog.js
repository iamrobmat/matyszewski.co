(function () {
  const blogRoot = document.getElementById("blog-app");

  if (!blogRoot) {
    return;
  }

  const postsUrl = "posts/posts.json";
  let posts = [];

  function escapeHtml(value) {
    return value
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function isSafeResourceUrl(value) {
    const trimmed = value.trim();

    return (
      !/[\s"'<>]/.test(trimmed) &&
      !trimmed.toLowerCase().startsWith("javascript:") &&
      /^(https?:\/\/|\.{0,2}\/|[a-z0-9_/-])/i.test(trimmed)
    );
  }

  function formatDate(value) {
    const date = new Date(`${value}T12:00:00`);

    return new Intl.DateTimeFormat("en", {
      year: "numeric",
      month: "short",
      day: "numeric",
    }).format(date);
  }

  function sortDate(value) {
    return new Date(`${value}T12:00:00`).getTime();
  }

  function getSlugFromHash() {
    const match = window.location.hash.match(/^#([a-z0-9-]+)$/);
    return match ? match[1] : null;
  }

  function renderInline(markdown) {
    const tokens = [];
    let safe = escapeHtml(markdown);

    safe = safe.replace(/`([^`]+)`/g, (_, code) => {
      const token = `@@CODE${tokens.length}@@`;
      tokens.push(`<code>${code}</code>`);
      return token;
    });

    safe = safe
      .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
      .replace(/\*([^*]+)\*/g, "<em>$1</em>")
      .replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)/g, '<a href="$2">$1</a>');

    tokens.forEach((tokenValue, index) => {
      safe = safe.replace(`@@CODE${index}@@`, tokenValue);
    });

    return safe;
  }

  function flushParagraph(buffer, html) {
    if (buffer.length === 0) {
      return;
    }

    html.push(`<p>${renderInline(buffer.join(" "))}</p>`);
    buffer.length = 0;
  }

  function flushList(buffer, html) {
    if (buffer.length === 0) {
      return;
    }

    html.push("<ul>");
    buffer.forEach((item) => html.push(`<li>${renderInline(item)}</li>`));
    html.push("</ul>");
    buffer.length = 0;
  }

  function markdownToHtml(markdown) {
    const lines = markdown.replace(/\r\n/g, "\n").split("\n");
    const html = [];
    const paragraph = [];
    const list = [];
    let inCodeBlock = false;
    let codeLines = [];

    lines.forEach((line) => {
      if (line.startsWith("```")) {
        flushParagraph(paragraph, html);
        flushList(list, html);

        if (inCodeBlock) {
          html.push(`<pre><code>${escapeHtml(codeLines.join("\n"))}</code></pre>`);
          codeLines = [];
          inCodeBlock = false;
          return;
        }

        inCodeBlock = true;
        return;
      }

      if (inCodeBlock) {
        codeLines.push(line);
        return;
      }

      if (!line.trim()) {
        flushParagraph(paragraph, html);
        flushList(list, html);
        return;
      }

      const image = line.match(/^!\[([^\]]*)\]\(([^)]+)\)$/);
      if (image) {
        flushParagraph(paragraph, html);
        flushList(list, html);

        const alt = image[1];
        const src = image[2].trim();

        if (isSafeResourceUrl(src)) {
          html.push(
            `<figure class="post-image"><img src="${escapeHtml(src)}" alt="${escapeHtml(alt)}" loading="lazy"></figure>`,
          );
          return;
        }
      }

      const heading = line.match(/^(#{1,3})\s+(.+)$/);
      if (heading) {
        flushParagraph(paragraph, html);
        flushList(list, html);
        const level = heading[1].length + 1;
        html.push(`<h${level}>${renderInline(heading[2])}</h${level}>`);
        return;
      }

      const listItem = line.match(/^-\s+(.+)$/);
      if (listItem) {
        flushParagraph(paragraph, html);
        list.push(listItem[1]);
        return;
      }

      if (line.startsWith("> ")) {
        flushParagraph(paragraph, html);
        flushList(list, html);
        html.push(`<blockquote>${renderInline(line.slice(2))}</blockquote>`);
        return;
      }

      flushList(list, html);
      paragraph.push(line.trim());
    });

    flushParagraph(paragraph, html);
    flushList(list, html);

    if (inCodeBlock) {
      html.push(`<pre><code>${escapeHtml(codeLines.join("\n"))}</code></pre>`);
    }

    return html.join("\n");
  }

  function renderPostList() {
    blogRoot.innerHTML = `
      <div class="post-list">
        ${posts
          .map(
            (post) => `
              <a class="post-row" href="#${post.slug}">
                <span>
                  <strong>${escapeHtml(post.title)}</strong>
                  <em>${escapeHtml(post.description)}</em>
                </span>
                <small>${formatDate(post.date)}</small>
              </a>
            `,
          )
          .join("")}
      </div>
    `;
  }

  async function renderPost(slug) {
    const post = posts.find((item) => item.slug === slug);

    if (!post) {
      blogRoot.innerHTML = `
        <article class="post-view">
          <a class="back-link" href="./">Back to all posts</a>
          <h2>Post not found</h2>
          <p>The requested Markdown file is not listed in <code>posts/posts.json</code>.</p>
        </article>
      `;
      return;
    }

    blogRoot.innerHTML = '<p class="blog-status">Loading post...</p>';

    try {
      const response = await fetch(`posts/${post.file}`);

      if (!response.ok) {
        throw new Error(`Could not load ${post.file}`);
      }

      const markdown = await response.text();
      blogRoot.innerHTML = `
        <article class="post-view">
          <a class="back-link" href="./">Back to all posts</a>
          <p class="post-date">${formatDate(post.date)}</p>
          <h2>${escapeHtml(post.title)}</h2>
          <div class="post-content">${markdownToHtml(markdown)}</div>
        </article>
      `;
    } catch (error) {
      blogRoot.innerHTML = `
        <article class="post-view">
          <a class="back-link" href="./">Back to all posts</a>
          <h2>Could not load post</h2>
          <p>${escapeHtml(error.message)}</p>
        </article>
      `;
    }
  }

  function renderCurrentRoute() {
    const slug = getSlugFromHash();

    if (slug) {
      renderPost(slug);
      return;
    }

    renderPostList();
  }

  async function initBlog() {
    try {
      const response = await fetch(postsUrl);

      if (!response.ok) {
        throw new Error("Could not load posts manifest.");
      }

      posts = await response.json();
      posts.sort((a, b) => sortDate(b.date) - sortDate(a.date));
      renderCurrentRoute();
    } catch (error) {
      blogRoot.innerHTML = `
        <p class="blog-status">Blog is unavailable: ${escapeHtml(error.message)}</p>
      `;
    }
  }

  window.addEventListener("hashchange", renderCurrentRoute);
  initBlog();
})();
