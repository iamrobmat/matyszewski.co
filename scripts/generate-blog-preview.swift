import AppKit
import Foundation
import ImageIO

struct Post: Decodable {
    let slug: String
    let title: String
    let metaTitle: String?
    let description: String
    let date: String
    let tags: [String]?
    let file: String
    // Optional photo header: `cover` is relative to blog/, like Markdown images.
    // `heroTitle` may mark one phrase with ==signal== for the yellow plate.
    let cover: String?
    let coverAlt: String?
    let kicker: String?
    let heroTitle: String?
}

struct MarkdownImage {
    let alt: String
    let src: String
    let caption: String?
    let size: (width: Int, height: Int)?

    var isPortrait: Bool {
        guard let size else {
            return false
        }
        return size.height > size.width
    }
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

func flushList(_ buffer: inout [String], into html: inout [String], tag: String = "ul") {
    if buffer.isEmpty {
        return
    }
    html.append("<\(tag)>")
    for item in buffer {
        html.append("<li>\(renderInline(item))</li>")
    }
    html.append("</\(tag)>")
    buffer.removeAll()
}

// A quote whose last line starts with "— " gets an attribution and the plate style.
func flushQuote(_ buffer: inout [String], into html: inout [String]) {
    if buffer.isEmpty {
        return
    }
    var lines = buffer
    var cite: String?
    if let last = lines.last, last.hasPrefix("— ") {
        cite = String(last.dropFirst(2))
        lines.removeLast()
    }

    if lines.count == 1, cite == nil {
        html.append("<blockquote>\(renderInline(lines[0]))</blockquote>")
    } else {
        let body = lines.map { "<p>\(renderInline($0))</p>" }.joined()
        let footer = cite.map { "<footer>\(renderInline($0))</footer>" } ?? ""
        let classAttribute = cite == nil ? "" : #" class="post-quote""#
        html.append("<blockquote\(classAttribute)>\(body)\(footer)</blockquote>")
    }
    buffer.removeAll()
}

func imageSize(at fileUrl: URL) -> (width: Int, height: Int)? {
    guard let source = CGImageSourceCreateWithURL(fileUrl as CFURL, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let width = properties[kCGImagePropertyPixelWidth] as? Int,
          let height = properties[kCGImagePropertyPixelHeight] as? Int else {
        return nil
    }
    let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
    return orientation >= 5 ? (height, width) : (width, height)
}

// Resolves a page-relative image URL to a file in the repository, so local images get intrinsic dimensions.
func localImageSize(_ src: String, pageDirectory: URL) -> (width: Int, height: Int)? {
    if src.hasPrefix("http://") || src.hasPrefix("https://") {
        return nil
    }
    let path = src.split(separator: "?", maxSplits: 1).first.map(String.init) ?? src
    let fileUrl = path.hasPrefix("/")
        ? root.appendingPathComponent(String(path.dropFirst()))
        : URL(fileURLWithPath: path, relativeTo: pageDirectory).standardizedFileURL
    return imageSize(at: fileUrl)
}

func renderFigure(_ image: MarkdownImage, className: String) -> String {
    let dimensions = image.size.map { #" width="\#($0.width)" height="\#($0.height)""# } ?? ""
    let caption = image.caption.map { "<figcaption>\(renderInline($0))</figcaption>" } ?? ""
    return #"<figure class="\#(className)"><img src="\#(escapeHtml(image.src))" alt="\#(escapeHtml(image.alt))"\#(dimensions) loading="lazy" decoding="async">\#(caption)</figure>"#
}

// Images on consecutive lines form one block: 1 = single figure, 2-3 = grid, 4+ = horizontal strip.
func flushImages(_ buffer: inout [MarkdownImage], into html: inout [String]) {
    if buffer.isEmpty {
        return
    }

    switch buffer.count {
    case 1:
        let orientation = buffer[0].isPortrait ? "is-portrait" : "is-landscape"
        html.append(renderFigure(buffer[0], className: "post-image \(orientation)"))
    case 2...3:
        let figures = buffer.map { renderFigure($0, className: "post-gallery-item") }.joined()
        html.append(#"<div class="post-gallery" data-count="\#(buffer.count)">\#(figures)</div>"#)
    default:
        let figures = buffer.map { renderFigure($0, className: "post-strip-item") }.joined()
        html.append(#"<div class="post-strip" role="region" aria-label="Galeria \#(buffer.count) obrazów, przewijana w poziomie" tabindex="0">\#(figures)</div>"#)
    }
    buffer.removeAll()
}

// ```stats fence: one "value | label" pair per line.
func renderStats(_ lines: [String]) -> String {
    let items = lines.compactMap { line -> String? in
        let parts = line.split(separator: "|", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2, !parts[0].isEmpty else {
            return nil
        }
        return "<li><strong>\(renderInline(parts[0]))</strong><span>\(renderInline(parts[1]))</span></li>"
    }
    return #"<ul class="post-stats">\#(items.joined())</ul>"#
}

func parseImage(_ line: String, resourcePrefix: String, pageDirectory: URL) -> MarkdownImage? {
    guard let match = line.range(of: #"^!\[([^\]]*)\]\(([^)]+)\)$"#, options: .regularExpression) else {
        return nil
    }
    let matched = String(line[match])
    let parts = matched.dropFirst(2).dropLast().split(separator: "](", maxSplits: 1).map(String.init)
    guard parts.count == 2 else {
        return nil
    }

    var target = parts[1].trimmingCharacters(in: .whitespaces)
    var caption: String?
    if let titleRange = target.range(of: #"\s+"[^"]*"$"#, options: .regularExpression) {
        caption = String(target[titleRange]).trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        target = String(target[..<titleRange.lowerBound])
    }

    guard let src = safeResourceUrl(target, prefixRelativeWith: resourcePrefix) else {
        return nil
    }
    return MarkdownImage(alt: parts[0], src: src, caption: caption, size: localImageSize(src, pageDirectory: pageDirectory))
}

func markdownToHtml(_ markdown: String, resourcePrefix: String, pageDirectory: URL) -> String {
    let lines = markdown.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    var html: [String] = []
    var paragraph: [String] = []
    var list: [String] = []
    var orderedList: [String] = []
    var quote: [String] = []
    var images: [MarkdownImage] = []
    var inCodeBlock = false
    var codeLanguage = ""
    var codeLines: [String] = []

    func flushBlocks(except kept: String = "") {
        if kept != "paragraph" { flushParagraph(&paragraph, into: &html) }
        if kept != "list" { flushList(&list, into: &html) }
        if kept != "orderedList" { flushList(&orderedList, into: &html, tag: "ol") }
        if kept != "quote" { flushQuote(&quote, into: &html) }
        if kept != "images" { flushImages(&images, into: &html) }
    }

    for line in lines {
        if line.hasPrefix("```") {
            flushBlocks()

            if inCodeBlock {
                if codeLanguage == "stats" {
                    html.append(renderStats(codeLines))
                } else {
                    html.append("<pre><code>\(escapeHtml(codeLines.joined(separator: "\n")))</code></pre>")
                }
                codeLines.removeAll()
                inCodeBlock = false
            } else {
                codeLanguage = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
                inCodeBlock = true
            }
            continue
        }

        if inCodeBlock {
            codeLines.append(line)
            continue
        }

        if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            flushBlocks()
            continue
        }

        if let image = parseImage(line, resourcePrefix: resourcePrefix, pageDirectory: pageDirectory) {
            flushBlocks(except: "images")
            images.append(image)
            continue
        }

        if let match = line.range(of: #"^(#{1,3})\s+(.+)$"#, options: .regularExpression) {
            let matched = String(line[match])
            let hashCount = matched.prefix { $0 == "#" }.count
            let text = matched.dropFirst(hashCount).trimmingCharacters(in: .whitespaces)
            let level = min(hashCount + 1, 4)
            flushBlocks()
            html.append("<h\(level)>\(renderInline(text))</h\(level)>")
            continue
        }

        if line.hasPrefix("- ") {
            flushBlocks(except: "list")
            list.append(String(line.dropFirst(2)))
            continue
        }

        if let match = line.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
            flushBlocks(except: "orderedList")
            orderedList.append(String(line[match.upperBound...]))
            continue
        }

        if line.hasPrefix("> ") {
            flushBlocks(except: "quote")
            quote.append(String(line.dropFirst(2)))
            continue
        }

        flushBlocks(except: "paragraph")
        paragraph.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    flushBlocks()

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

func generateSocialCard(
    title: String,
    description: String,
    outputBaseName: String,
    footerUrl: String,
    label: String? = "BLOG",
    showsSubtitle: Bool = true,
    ctaText: String = "Czytaj blog"
) throws -> String {
    let lines = titleLines(title)
    let fontSize = lines.count >= 3 ? 54 : (lines.count == 2 ? 68 : 76)
    let firstTextTop: Int
    if showsSubtitle {
        firstTextTop = lines.count >= 3 ? 274 : (lines.count == 2 ? 266 : 326)
    } else {
        firstTextTop = lines.count >= 3 ? 222 : (lines.count == 2 ? 235 : 277)
    }
    let lineSpacing = lines.count >= 3 ? 62 : 80
    let ctaTop = showsSubtitle ? 492 : 482
    let ctaWidth = ctaText == "Czytaj blog" ? 190 : 220
    let ctaTextX = 96 + (ctaWidth / 2)
    let footerTextX = 96 + ctaWidth + 24
    let subtitle = showsSubtitle ? shortDescription(description) : nil
    let profileImageName = "robert-matyszewski-profile.png"

    let svg = """
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <defs>
    <pattern id="grid" width="36" height="36" patternUnits="userSpaceOnUse">
      <path d="M36 0H0V36" fill="none" stroke="#151515" stroke-opacity="0.045" stroke-width="1"/>
    </pattern>
    <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="20" stdDeviation="24" flood-color="#151515" flood-opacity="0.14"/>
    </filter>
    <clipPath id="profile-clip">
      <circle cx="956" cy="315" r="136"/>
    </clipPath>
  </defs>

  <rect width="1200" height="630" fill="#f8f8f5"/>
  <rect width="1200" height="630" fill="url(#grid)"/>
  <rect x="32" y="32" width="1136" height="566" rx="18" fill="#ffffff" fill-opacity="0.88" stroke="#151515" stroke-opacity="0.14" filter="url(#shadow)"/>
  <text x="96" y="142" fill="#151515" font-family="Inter, Arial, sans-serif" font-size="30" font-weight="800">matyszewski.co</text>
  <image href="\(profileImageName)" x="820" y="179" width="272" height="272" preserveAspectRatio="xMidYMid slice" clip-path="url(#profile-clip)"/>
  <circle cx="956" cy="315" r="136" fill="none" stroke="#151515" stroke-opacity="0.14" stroke-width="2"/>
\(label.map { ##"  <text x="96" y="236" fill="#1f6b4a" font-family="Inter, Arial, sans-serif" font-size="26" font-weight="800" letter-spacing="3">\##(escapeHtml($0))</text>"## } ?? "")
\(svgTextLines(lines, fontSize: fontSize, top: firstTextTop, spacing: lineSpacing))
\(subtitle.map { ##"  <text x="96" y="466" fill="#303330" font-family="Inter, Arial, sans-serif" font-size="24" font-weight="600">\##(escapeHtml($0))</text>"## } ?? "")
  <rect x="96" y="\(ctaTop)" width="\(ctaWidth)" height="48" rx="12" fill="#1f6b4a"/>
  <text x="\(ctaTextX)" y="\(ctaTop + 31)" fill="#ffffff" font-family="Inter, Arial, sans-serif" font-size="21" font-weight="800" text-anchor="middle">\(escapeHtml(ctaText))</text>
  <text x="\(footerTextX)" y="\(ctaTop + 31)" fill="#5e625f" font-family="Inter, Arial, sans-serif" font-size="21" font-weight="600">\(escapeHtml(footerUrl))</text>
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
        ctaTop: CGFloat(ctaTop),
        ctaText: ctaText,
        ctaWidth: CGFloat(ctaWidth),
        profileImage: socialDir.appendingPathComponent(profileImageName),
        output: socialDir.appendingPathComponent("\(outputBaseName).png")
    )

    return try imageVersion(at: socialDir.appendingPathComponent("\(outputBaseName).png"))
}

func imageVersion(at imageUrl: URL) throws -> String {
    let bytes = try Data(contentsOf: imageUrl)
    var hash: UInt64 = 0xcbf29ce484222325

    for byte in bytes {
        hash ^= UInt64(byte)
        hash = hash &* 0x100000001b3
    }

    return String(format: "%016llx", hash)
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
    subtitle: String?,
    footerUrl: String,
    label: String?,
    fontSize: CGFloat,
    firstTextTop: CGFloat,
    lineSpacing: CGFloat,
    ctaTop: CGFloat,
    ctaText: String,
    ctaWidth: CGFloat,
    profileImage: URL,
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
        roundedRect: NSRect(x: 32, y: topY(32, 566), width: 1136, height: 566),
        xRadius: 18,
        yRadius: 18
    )
    color(0xffffff, 0.88).setFill()
    card.fill()
    NSShadow().set()
    color(0x151515, 0.14).setStroke()
    card.lineWidth = 1
    card.stroke()

    drawText("matyszewski.co", x: 96, top: 108, w: 360, h: 42, size: 30, weight: .heavy, fill: color(0x151515))

    guard let portrait = NSImage(contentsOf: profileImage) else {
        throw NSError(
            domain: "SocialCard",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Could not load profile image at \(profileImage.path)"]
        )
    }
    let portraitRect = NSRect(x: 820, y: topY(179, 272), width: 272, height: 272)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(ovalIn: portraitRect).addClip()
    portrait.draw(in: portraitRect, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    color(0x151515, 0.14).setStroke()
    let portraitBorder = NSBezierPath(ovalIn: portraitRect)
    portraitBorder.lineWidth = 2
    portraitBorder.stroke()

    if let label {
        drawText(label, x: 96, top: 214, w: 240, h: 34, size: 26, weight: .heavy, fill: color(0x1f6b4a), spacing: 3)
    }
    for (index, line) in titleLines.enumerated() {
        drawText(line, x: 96, top: firstTextTop + (CGFloat(index) * lineSpacing), w: 690, h: lineSpacing, size: fontSize, weight: .heavy, fill: color(0x151515))
    }

    if let subtitle {
        drawText(subtitle, x: 96, top: 439, w: 820, h: 34, size: 24, weight: .semibold, fill: color(0x303330))
    }

    let cta = NSBezierPath(
        roundedRect: NSRect(x: 96, y: topY(ctaTop, 48), width: ctaWidth, height: 48),
        xRadius: 12,
        yRadius: 12
    )
    color(0x1f6b4a).setFill()
    cta.fill()
    drawText(ctaText, x: 96, top: ctaTop + 10, w: ctaWidth, h: 28, size: 21, weight: .heavy, fill: color(0xffffff), alignment: .center)
    drawText(footerUrl, x: 96 + ctaWidth + 24, top: ctaTop + 10, w: 470, h: 28, size: 21, weight: .semibold, fill: color(0x5e625f))

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

func metadataTitle(for post: Post) -> String {
    if let metaTitle = post.metaTitle {
        return metaTitle
    }

    let brandedTitle = "\(post.title) - Blog Roberta Matyszewskiego"
    return brandedTitle.count <= 60 ? brandedTitle : post.title
}

func syncNavigation() throws {
    let process = Process()
    let output = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["node", root.appendingPathComponent("scripts/sync-navigation.mjs").path, root.path]
    process.currentDirectoryURL = root
    process.standardOutput = output
    process.standardError = output

    try process.run()
    process.waitUntilExit()

    let data = output.fileHandleForReading.readDataToEndOfFile()
    let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    guard process.terminationStatus == 0 else {
        throw NSError(
            domain: "NavigationSync",
            code: Int(process.terminationStatus),
            userInfo: [NSLocalizedDescriptionKey: message.isEmpty ? "Navigation sync failed." : message]
        )
    }

    if !message.isEmpty {
        print(message)
    }
}

func renderStructuredData(post: Post, postUrl: String, imageUrl: String) throws -> String {
    var data: [String: Any] = [
        "@context": "https://schema.org",
        "@type": "BlogPosting",
        "headline": post.title,
        "description": post.description,
        "datePublished": post.date,
        "inLanguage": "pl",
        "url": postUrl,
        "mainEntityOfPage": postUrl,
        "image": imageUrl,
        "author": [
            "@type": "Person",
            "@id": "\(siteOrigin)/#person",
            "name": "Robert Matyszewski",
            "url": "\(siteOrigin)/",
        ],
    ]

    if let tags = post.tags, !tags.isEmpty {
        data["keywords"] = tags
    }

    let json = try JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    return (String(data: json, encoding: .utf8) ?? "{}")
        .replacingOccurrences(of: "</", with: "<\\/")
        .split(separator: "\n")
        .map { "      \($0)" }
        .joined(separator: "\n")
}

func renderHeroTitle(_ title: String) -> String {
    replaceRegex(#"==(.+?)=="#, in: escapeHtml(title)) { match, value in
        #"<span class="hero-signal">\#(capture(1, from: match, in: value))</span>"#
    }
}

func renderCoverArticle(post: Post, contentHtml: String, pageDirectory: URL) -> String {
    let coverSrc = post.cover.flatMap { safeResourceUrl($0, prefixRelativeWith: "../") } ?? ""
    let coverSize = localImageSize(coverSrc, pageDirectory: pageDirectory)
    let dimensions = coverSize.map { #" width="\#($0.width)" height="\#($0.height)""# } ?? ""
    let kicker = post.kicker.map { #"<p class="eyebrow">\#(escapeHtml($0))</p>"# } ?? ""
    return """
      <article class="post-article">
        <header class="post-hero">
          <div class="post-hero-copy">
            <a class="back-link" href="../">Wróć do wszystkich wpisów</a>
            \(kicker)
            <h1>\(renderHeroTitle(post.heroTitle ?? post.title))</h1>
            <p class="lead">\(escapeHtml(post.description))</p>
            <div class="post-hero-meta">
              <p class="post-date">\(escapeHtml(post.date))</p>
              \(renderTags(post.tags))
            </div>
          </div>
          <figure class="post-hero-media">
            <img src="\(escapeHtml(coverSrc))" alt="\(escapeHtml(post.coverAlt ?? ""))"\(dimensions) fetchpriority="high">
          </figure>
        </header>
        <section class="section post-body">
          <div class="post-content">\(contentHtml)</div>
        </section>
      </article>
"""
}

func renderPostPage(post: Post, markdown: String, imageVersion: String) throws {
    let postDir = root.appendingPathComponent("blog/\(post.slug)", isDirectory: true)
    try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)

    let metaTitle = metadataTitle(for: post)
    let postUrl = "\(siteOrigin)/blog/\(post.slug)/"
    let imageUrl = "\(siteOrigin)/blog/assets/social/\(post.slug).png?v=\(imageVersion)"
    let contentHtml = markdownToHtml(markdown, resourcePrefix: "../", pageDirectory: postDir)
    let structuredData = try renderStructuredData(post: post, postUrl: postUrl, imageUrl: imageUrl)
    let mainHtml = post.cover == nil
        ? """
      <section class="section blog-page">
        <article class="post-view">
          <a class="back-link" href="../">Wróć do wszystkich wpisów</a>
          <p class="post-date">\(escapeHtml(post.date))</p>
          <h2>\(escapeHtml(post.title))</h2>
          \(renderTags(post.tags))
          <div class="post-content">\(contentHtml)</div>
        </article>
      </section>
"""
        : renderCoverArticle(post: post, contentHtml: contentHtml, pageDirectory: postDir)
    let page = """
<!doctype html>
<html lang="pl">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>\(escapeHtml(metaTitle))</title>
    <meta name="title" content="\(escapeHtml(metaTitle))">
    <meta name="description" content="\(escapeHtml(post.description))">
    <meta property="og:title" content="\(escapeHtml(metaTitle))">
    <meta property="og:description" content="\(escapeHtml(post.description))">
    <meta property="og:site_name" content="Robert Matyszewski">
    <meta property="og:type" content="article">
    <meta property="og:url" content="\(postUrl)">
    <meta property="og:image" content="\(imageUrl)">
    <meta property="og:image:width" content="1200">
    <meta property="og:image:height" content="630">
    <meta property="og:image:alt" content="\(escapeHtml(post.title))">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="\(escapeHtml(metaTitle))">
    <meta name="twitter:description" content="\(escapeHtml(post.description))">
    <meta name="twitter:image" content="\(imageUrl)">
    <meta name="twitter:image:alt" content="\(escapeHtml(post.title))">
    <link rel="canonical" href="\(postUrl)">
    <link rel="stylesheet" href="../../styles.css">
    <link rel="stylesheet" href="../blog.css">
    <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='12' fill='%23151515'/%3E%3Cpath d='M15 45V19h8l9 14 9-14h8v26h-7V29L34 42h-4l-8-13v16z' fill='%23f8f8f5'/%3E%3C/svg%3E">
    <script src="../../analytics-config.js" defer></script>
    <script src="../../analytics.js" defer></script>
    <script type="application/ld+json">
\(structuredData)
    </script>
  </head>
  <body>
    <header class="site-header">
      <a class="brand" href="../../" aria-label="Strona główna Roberta Matyszewskiego">
        <span class="brand-mark">RM</span>
        <span>Robert Matyszewski</span>
      </a>
      <nav class="nav" aria-label="Główna nawigacja" data-nav-current="blog"></nav>
    </header>

    <main id="top">
\(mainHtml)
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

func updatingSocialImageMetadata(in html: String, imageUrl: String) -> String {
    html
        .replacingOccurrences(
            of: #"<meta property="og:image" content="[^"]*">"#,
            with: #"<meta property="og:image" content="\#(imageUrl)">"#,
            options: .regularExpression
        )
        .replacingOccurrences(
            of: #"<meta name="twitter:image" content="[^"]*">"#,
            with: #"<meta name="twitter:image" content="\#(imageUrl)">"#,
            options: .regularExpression
        )
}

let html = try String(contentsOf: blogIndex, encoding: .utf8)
let blogTitle = firstMatch(#"<title>\s*(.*?)\s*</title>"#, in: html) ?? "Blog Roberta Matyszewskiego"
let blogDescription = firstMatch(#"<meta\s+name="description"\s+content="([^"]+)""#, in: html) ?? blogDescriptionFallback
let posts = try JSONDecoder().decode([Post].self, from: Data(contentsOf: postsJson))

try FileManager.default.createDirectory(at: socialDir, withIntermediateDirectories: true)
let blogImageVersion = try generateSocialCard(title: blogTitle, description: blogDescription, outputBaseName: "blog-preview", footerUrl: "matyszewski.co/blog")
let versionedBlogIndex = updatingSocialImageMetadata(
    in: html,
    imageUrl: "\(siteOrigin)/blog/assets/social/blog-preview.png?v=\(blogImageVersion)"
)
if versionedBlogIndex != html {
    try versionedBlogIndex.write(to: blogIndex, atomically: true, encoding: .utf8)
}

for post in posts {
    let markdown = try String(contentsOf: postsDir.appendingPathComponent(post.file), encoding: .utf8)
    let postImageVersion = try generateSocialCard(
        title: post.metaTitle ?? post.title,
        description: post.description,
        outputBaseName: post.slug,
        footerUrl: "matyszewski.co/blog",
        label: nil,
        showsSubtitle: false,
        ctaText: "Przeczytaj wpis"
    )
    try renderPostPage(post: post, markdown: markdown, imageVersion: postImageVersion)
}

try syncNavigation()

print("Generated blog preview, \(posts.count) post pages and \(posts.count) post preview images.")
