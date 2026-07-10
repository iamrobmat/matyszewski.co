import AppKit
import Foundation

struct Post: Decodable {
    let slug: String
    let title: String
    let description: String
    let date: String
    let tags: [String]?
    let file: String
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let blogIndex = root.appendingPathComponent("blog/index.html")
let postsJson = root.appendingPathComponent("blog/posts/posts.json")
let postsDir = root.appendingPathComponent("blog/posts", isDirectory: true)
let socialDir = root.appendingPathComponent("blog/assets/social", isDirectory: true)
let siteOrigin = "https://matyszewski.co"
let blogDescriptionFallback = "Notatki Roberta Matyszewskiego o AI, produktach, sprzedaży oprogramowania i budowaniu lokalnego ekosystemu technologicznego."

func firstMatch(_ pattern: String, in value: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
          let match = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)),
          match.numberOfRanges > 1,
          let range = Range(match.range(at: 1), in: value) else {
        return nil
    }

    return decodeHtml(String(value[range])).trimmingCharacters(in: .whitespacesAndNewlines)
}

func decodeHtml(_ value: String) -> String {
    value
        .replacingOccurrences(of: "&amp;", with: "&")
        .replacingOccurrences(of: "&quot;", with: "\"")
        .replacingOccurrences(of: "&#039;", with: "'")
        .replacingOccurrences(of: "&lt;", with: "<")
        .replacingOccurrences(of: "&gt;", with: ">")
}

func escapeHtml(_ value: String) -> String {
    value
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&#039;")
}

func safeResourceUrl(_ value: String, prefixRelativeWith prefix: String) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.range(of: #"[\s"'<>]"#, options: .regularExpression) != nil {
        return nil
    }
    if trimmed.lowercased().hasPrefix("javascript:") {
        return nil
    }
    if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") || trimmed.hasPrefix("/") || trimmed.hasPrefix("../") || trimmed.hasPrefix("./") {
        return trimmed
    }
    return prefix + trimmed
}

func replaceRegex(_ pattern: String, in value: String, using transform: (NSTextCheckingResult, String) -> String) -> String {
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return value
    }

    let matches = regex.matches(in: value, range: NSRange(value.startIndex..., in: value)).reversed()
    var output = value

    for match in matches {
        guard let range = Range(match.range, in: output) else {
            continue
        }
        output.replaceSubrange(range, with: transform(match, output))
    }

    return output
}

func capture(_ index: Int, from match: NSTextCheckingResult, in value: String) -> String {
    guard let range = Range(match.range(at: index), in: value) else {
        return ""
    }
    return String(value[range])
}

func renderInline(_ markdown: String) -> String {
    var tokens: [String] = []
    var safe = escapeHtml(markdown)

    safe = replaceRegex(#"`([^`]+)`"#, in: safe) { match, value in
        let token = "@@CODE\(tokens.count)@@"
        tokens.append("<code>\(capture(1, from: match, in: value))</code>")
        return token
    }

    safe = replaceRegex(#"\*\*([^*]+)\*\*"#, in: safe) { match, value in
        "<strong>\(capture(1, from: match, in: value))</strong>"
    }
    safe = replaceRegex(#"\*([^*]+)\*"#, in: safe) { match, value in
        "<em>\(capture(1, from: match, in: value))</em>"
    }
    safe = replaceRegex(#"\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)"#, in: safe) { match, value in
        let label = capture(1, from: match, in: value)
        let href = capture(2, from: match, in: value)
        return #"<a href="\#(href)">\#(label)</a>"#
    }

    for (index, tokenValue) in tokens.enumerated() {
        safe = safe.replacingOccurrences(of: "@@CODE\(index)@@", with: tokenValue)
    }

    return safe
}

func flushParagraph(_ buffer: inout [String], into html: inout [String]) {
    if buffer.isEmpty {
        return
    }
    html.append("<p>\(renderInline(buffer.joined(separator: " ")))</p>")
    buffer.removeAll()
}

func flushList(_ buffer: inout [String], into html: inout [String]) {
    if buffer.isEmpty {
        return
    }
    html.append("<ul>")
    for item in buffer {
        html.append("<li>\(renderInline(item))</li>")
    }
    html.append("</ul>")
    buffer.removeAll()
}

func markdownToHtml(_ markdown: String, resourcePrefix: String) -> String {
    let lines = markdown.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    var html: [String] = []
    var paragraph: [String] = []
    var list: [String] = []
    var inCodeBlock = false
    var codeLines: [String] = []

    for line in lines {
        if line.hasPrefix("```") {
            flushParagraph(&paragraph, into: &html)
            flushList(&list, into: &html)

            if inCodeBlock {
                html.append("<pre><code>\(escapeHtml(codeLines.joined(separator: "\n")))</code></pre>")
                codeLines.removeAll()
                inCodeBlock = false
            } else {
                inCodeBlock = true
            }
            continue
        }

        if inCodeBlock {
            codeLines.append(line)
            continue
        }

        if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            flushParagraph(&paragraph, into: &html)
            flushList(&list, into: &html)
            continue
        }

        if let match = line.range(of: #"^!\[([^\]]*)\]\(([^)]+)\)$"#, options: .regularExpression) {
            let matched = String(line[match])
            let parts = matched.dropFirst(2).dropLast().split(separator: "](", maxSplits: 1).map(String.init)
            if parts.count == 2, let src = safeResourceUrl(parts[1], prefixRelativeWith: resourcePrefix) {
                flushParagraph(&paragraph, into: &html)
                flushList(&list, into: &html)
                html.append(#"<figure class="post-image"><img src="\#(escapeHtml(src))" alt="\#(escapeHtml(parts[0]))" loading="lazy"></figure>"#)
                continue
            }
        }

        if let match = line.range(of: #"^(#{1,3})\s+(.+)$"#, options: .regularExpression) {
            let matched = String(line[match])
            let hashCount = matched.prefix { $0 == "#" }.count
            let text = matched.dropFirst(hashCount).trimmingCharacters(in: .whitespaces)
            let level = min(hashCount + 1, 4)
            flushParagraph(&paragraph, into: &html)
            flushList(&list, into: &html)
            html.append("<h\(level)>\(renderInline(text))</h\(level)>")
            continue
        }

        if line.hasPrefix("- ") {
            flushParagraph(&paragraph, into: &html)
            list.append(String(line.dropFirst(2)))
            continue
        }

        if line.hasPrefix("> ") {
            flushParagraph(&paragraph, into: &html)
            flushList(&list, into: &html)
            html.append("<blockquote>\(renderInline(String(line.dropFirst(2))))</blockquote>")
            continue
        }

        flushList(&list, into: &html)
        paragraph.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    flushParagraph(&paragraph, into: &html)
    flushList(&list, into: &html)

    if inCodeBlock {
        html.append("<pre><code>\(escapeHtml(codeLines.joined(separator: "\n")))</code></pre>")
    }

    return html.joined(separator: "\n")
}

func titleLines(_ title: String) -> [String] {
    let words = title.split(separator: " ").map(String.init)
    var lines: [String] = []
    var current = ""
    let maxLineLength = title.count > 42 ? 22 : 18

    for word in words {
        let candidate = current.isEmpty ? word : "\(current) \(word)"
        if candidate.count <= maxLineLength || current.isEmpty {
            current = candidate
        } else {
            lines.append(current)
            current = word
        }
    }

    if !current.isEmpty {
        lines.append(current)
    }

    return Array(lines.prefix(3))
}

func shortDescription(_ description: String) -> String {
    if description.contains("AI, produktach, sprzedaży oprogramowania") {
        return "AI, produkty i sprzedaż oprogramowania"
    }
    let cleaned = description
        .replacingOccurrences(of: "Notatki Roberta Matyszewskiego o ", with: "")
        .replacingOccurrences(of: " i budowaniu lokalnego ekosystemu technologicznego.", with: "")
    return cleaned.count > 50 ? String(cleaned.prefix(47)) + "..." : cleaned
}

func svgTextLines(_ lines: [String], fontSize: Int, top: Int, spacing: Int) -> String {
    lines.enumerated().map { index, line in
        let y = top + (index * spacing)
        return ##"  <text x="96" y="\##(y)" fill="#151515" font-family="Inter, Arial, sans-serif" font-size="\##(fontSize)" font-weight="800">\##(escapeHtml(line))</text>"##
    }.joined(separator: "\n")
}

func generateSocialCard(title: String, description: String, outputBaseName: String, footerUrl: String, label: String = "BLOG") throws {
    let lines = titleLines(title)
    let fontSize = lines.count >= 3 ? 54 : 76
    let firstTextTop = lines.count >= 3 ? 274 : 330
    let lineSpacing = lines.count >= 3 ? 62 : 88
    let dividerTop = lines.count >= 3 ? 472 : 468
    let descriptionTop = lines.count >= 3 ? 494 : 516
    let footerTop = lines.count >= 3 ? 528 : 546
    let subtitle = shortDescription(description)

    let svg = """
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <defs>
    <pattern id="grid" width="36" height="36" patternUnits="userSpaceOnUse">
      <path d="M36 0H0V36" fill="none" stroke="#151515" stroke-opacity="0.045" stroke-width="1"/>
    </pattern>
    <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="20" stdDeviation="24" flood-color="#151515" flood-opacity="0.14"/>
    </filter>
  </defs>

  <rect width="1200" height="630" fill="#f8f8f5"/>
  <rect width="1200" height="630" fill="url(#grid)"/>
  <rect x="72" y="72" width="1056" height="486" rx="18" fill="#ffffff" fill-opacity="0.88" stroke="#151515" stroke-opacity="0.14" filter="url(#shadow)"/>
  <rect x="96" y="96" width="74" height="74" rx="14" fill="#151515"/>
  <text x="133" y="143" fill="#f8f8f5" font-family="Inter, Arial, sans-serif" font-size="24" font-weight="800" text-anchor="middle">RM</text>
  <text x="96" y="236" fill="#1f6b4a" font-family="Inter, Arial, sans-serif" font-size="26" font-weight="800" letter-spacing="3">\(escapeHtml(label))</text>
\(svgTextLines(lines, fontSize: fontSize, top: firstTextTop, spacing: lineSpacing))
  <rect x="96" y="\(dividerTop)" width="606" height="1" fill="#d8ddd6"/>
  <text x="96" y="\(descriptionTop)" fill="#303330" font-family="Inter, Arial, sans-serif" font-size="30" font-weight="600">\(escapeHtml(subtitle))</text>
  <text x="96" y="\(footerTop)" fill="#5e625f" font-family="Inter, Arial, sans-serif" font-size="24" font-weight="600">\(escapeHtml(footerUrl))</text>
  <circle cx="1007" cy="174" r="42" fill="#d8b23f"/>
  <circle cx="1059" cy="230" r="30" fill="#285f9f"/>
  <circle cx="1000" cy="277" r="22" fill="#a9412f"/>
</svg>
"""

    try svg.write(to: socialDir.appendingPathComponent("\(outputBaseName).svg"), atomically: true, encoding: .utf8)
    try renderPngCard(
        titleLines: lines,
        subtitle: subtitle,
        footerUrl: footerUrl,
        label: label,
        fontSize: CGFloat(fontSize),
        firstTextTop: CGFloat(firstTextTop),
        lineSpacing: CGFloat(lineSpacing),
        dividerTop: CGFloat(dividerTop),
        descriptionTop: CGFloat(descriptionTop),
        footerTop: CGFloat(footerTop),
        output: socialDir.appendingPathComponent("\(outputBaseName).png")
    )
}

func color(_ hex: UInt32, _ alpha: CGFloat = 1.0) -> NSColor {
    NSColor(
        calibratedRed: CGFloat((hex >> 16) & 0xff) / 255.0,
        green: CGFloat((hex >> 8) & 0xff) / 255.0,
        blue: CGFloat(hex & 0xff) / 255.0,
        alpha: alpha
    )
}

func renderPngCard(
    titleLines: [String],
    subtitle: String,
    footerUrl: String,
    label: String,
    fontSize: CGFloat,
    firstTextTop: CGFloat,
    lineSpacing: CGFloat,
    dividerTop: CGFloat,
    descriptionTop: CGFloat,
    footerTop: CGFloat,
    output: URL
) throws {
    let width: CGFloat = 1200
    let height: CGFloat = 630
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    guard let bitmapContext = CGContext(
        data: nil,
        width: Int(width),
        height: Int(height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Could not create bitmap context")
    }

    let context = NSGraphicsContext(cgContext: bitmapContext, flipped: false)

    func topY(_ top: CGFloat, _ objectHeight: CGFloat) -> CGFloat {
        height - top - objectHeight
    }

    func drawText(
        _ text: String,
        x: CGFloat,
        top: CGFloat,
        w: CGFloat,
        h: CGFloat,
        size: CGFloat,
        weight: NSFont.Weight,
        fill: NSColor,
        spacing: CGFloat = 0,
        alignment: NSTextAlignment = .left
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = alignment
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: fill,
            .paragraphStyle: paragraph,
            .kern: spacing,
        ]
        NSString(string: text).draw(
            in: NSRect(x: x, y: topY(top, h), width: w, height: h),
            withAttributes: attrs
        )
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    color(0xf8f8f5).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()

    color(0x151515, 0.045).setStroke()
    for x in stride(from: CGFloat(0), through: width, by: 36) {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: x, y: 0))
        path.line(to: NSPoint(x: x, y: height))
        path.stroke()
    }
    for y in stride(from: CGFloat(0), through: height, by: 36) {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 0, y: y))
        path.line(to: NSPoint(x: width, y: y))
        path.stroke()
    }

    let shadow = NSShadow()
    shadow.shadowOffset = NSSize(width: 0, height: -18)
    shadow.shadowBlurRadius = 26
    shadow.shadowColor = color(0x151515, 0.12)
    shadow.set()

    let card = NSBezierPath(
        roundedRect: NSRect(x: 72, y: topY(72, 486), width: 1056, height: 486),
        xRadius: 18,
        yRadius: 18
    )
    color(0xffffff, 0.88).setFill()
    card.fill()
    NSShadow().set()
    color(0x151515, 0.14).setStroke()
    card.lineWidth = 1
    card.stroke()

    let mark = NSBezierPath(
        roundedRect: NSRect(x: 96, y: topY(96, 74), width: 74, height: 74),
        xRadius: 14,
        yRadius: 14
    )
    color(0x151515).setFill()
    mark.fill()
    drawText("RM", x: 96, top: 119, w: 74, h: 30, size: 24, weight: .heavy, fill: color(0xf8f8f5), alignment: .center)

    drawText(label, x: 96, top: 214, w: 240, h: 34, size: 26, weight: .heavy, fill: color(0x1f6b4a), spacing: 3)
    for (index, line) in titleLines.enumerated() {
        drawText(line, x: 96, top: firstTextTop + (CGFloat(index) * lineSpacing), w: 920, h: lineSpacing, size: fontSize, weight: .heavy, fill: color(0x151515))
    }

    color(0xd8ddd6).setStroke()
    let divider = NSBezierPath()
    divider.move(to: NSPoint(x: 96, y: topY(dividerTop, 1)))
    divider.line(to: NSPoint(x: 702, y: topY(dividerTop, 1)))
    divider.lineWidth = 1
    divider.stroke()

    drawText(subtitle, x: 96, top: descriptionTop, w: 820, h: 42, size: 30, weight: .semibold, fill: color(0x303330))
    drawText(footerUrl, x: 96, top: footerTop, w: 520, h: 32, size: 24, weight: .semibold, fill: color(0x5e625f))

    color(0xd8b23f).setFill()
    NSBezierPath(ovalIn: NSRect(x: 965, y: topY(132, 84), width: 84, height: 84)).fill()
    color(0x285f9f).setFill()
    NSBezierPath(ovalIn: NSRect(x: 1029, y: topY(200, 60), width: 60, height: 60)).fill()
    color(0xa9412f).setFill()
    NSBezierPath(ovalIn: NSRect(x: 978, y: topY(255, 44), width: 44, height: 44)).fill()

    NSGraphicsContext.restoreGraphicsState()

    guard let cgImage = bitmapContext.makeImage(),
          let png = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:]) else {
        fatalError("Could not encode PNG")
    }

    try png.write(to: output)
}

func renderTags(_ tags: [String]?) -> String {
    guard let tags, !tags.isEmpty else {
        return ""
    }
    return """
          <ul class="post-tags" aria-label="Tagi wpisu">
            \(tags.map { "<li>\(escapeHtml($0))</li>" }.joined(separator: "\n            "))
          </ul>
"""
}

func renderPostPage(post: Post, markdown: String) throws {
    let postDir = root.appendingPathComponent("blog/\(post.slug)", isDirectory: true)
    try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)

    let title = "\(post.title) - Blog Roberta Matyszewskiego"
    let postUrl = "\(siteOrigin)/blog/\(post.slug)/"
    let imageUrl = "\(siteOrigin)/blog/assets/social/\(post.slug).png"
    let contentHtml = markdownToHtml(markdown, resourcePrefix: "../")
    let page = """
<!doctype html>
<html lang="pl">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>\(escapeHtml(title))</title>
    <meta name="title" content="\(escapeHtml(title))">
    <meta name="description" content="\(escapeHtml(post.description))">
    <meta property="og:title" content="\(escapeHtml(title))">
    <meta property="og:description" content="\(escapeHtml(post.description))">
    <meta property="og:type" content="article">
    <meta property="og:url" content="\(postUrl)">
    <meta property="og:image" content="\(imageUrl)">
    <meta property="og:image:width" content="1200">
    <meta property="og:image:height" content="630">
    <meta property="og:image:alt" content="\(escapeHtml(post.title))">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="\(escapeHtml(title))">
    <meta name="twitter:description" content="\(escapeHtml(post.description))">
    <meta name="twitter:image" content="\(imageUrl)">
    <meta name="twitter:image:alt" content="\(escapeHtml(post.title))">
    <link rel="canonical" href="\(postUrl)">
    <link rel="stylesheet" href="../../styles.css">
    <link rel="stylesheet" href="../blog.css">
    <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='12' fill='%23151515'/%3E%3Cpath d='M15 45V19h8l9 14 9-14h8v26h-7V29L34 42h-4l-8-13v16z' fill='%23f8f8f5'/%3E%3C/svg%3E">
  </head>
  <body>
    <header class="site-header">
      <a class="brand" href="../../" aria-label="Strona główna Roberta Matyszewskiego">
        <span class="brand-mark">RM</span>
        <span>Robert Matyszewski</span>
      </a>
      <nav class="nav" aria-label="Główna nawigacja">
        <a href="../../#work">Praca</a>
        <a href="../../#projects">Projekty</a>
        <a href="../">Blog</a>
        <a href="../../#contact">Kontakt</a>
      </nav>
    </header>

    <main id="top">
      <section class="section blog-page">
        <article class="post-view">
          <a class="back-link" href="../">Wróć do wszystkich wpisów</a>
          <p class="post-date">\(escapeHtml(post.date))</p>
          <h2>\(escapeHtml(post.title))</h2>
          \(renderTags(post.tags))
          <div class="post-content">\(contentHtml)</div>
        </article>
      </section>
    </main>

    <footer class="site-footer">
      <span>© <span id="year">2026</span> Robert Matyszewski</span>
      <a href="#top">Wróć na górę</a>
    </footer>

    <script>
      document.getElementById("year").textContent = new Date().getFullYear();
    </script>
  </body>
</html>
"""

    try page.write(to: postDir.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
}

let html = try String(contentsOf: blogIndex, encoding: .utf8)
let blogTitle = firstMatch(#"<title>\s*(.*?)\s*</title>"#, in: html) ?? "Blog Roberta Matyszewskiego"
let blogDescription = firstMatch(#"<meta\s+name="description"\s+content="([^"]+)""#, in: html) ?? blogDescriptionFallback
let posts = try JSONDecoder().decode([Post].self, from: Data(contentsOf: postsJson))

try FileManager.default.createDirectory(at: socialDir, withIntermediateDirectories: true)
try generateSocialCard(title: blogTitle, description: blogDescription, outputBaseName: "blog-preview", footerUrl: "matyszewski.co/blog")

for post in posts {
    let markdown = try String(contentsOf: postsDir.appendingPathComponent(post.file), encoding: .utf8)
    try generateSocialCard(title: post.title, description: post.description, outputBaseName: post.slug, footerUrl: "matyszewski.co/blog", label: "WPIS")
    try renderPostPage(post: post, markdown: markdown)
}

print("Generated blog preview, \(posts.count) post pages and \(posts.count) post preview images.")
