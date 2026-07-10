import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let blogIndex = root.appendingPathComponent("blog/index.html")
let outputDir = root.appendingPathComponent("blog/assets/social", isDirectory: true)
let outputPng = outputDir.appendingPathComponent("blog-preview.png")
let outputSvg = outputDir.appendingPathComponent("blog-preview.svg")

let html = try String(contentsOf: blogIndex, encoding: .utf8)

func firstMatch(_ pattern: String, in value: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
          let match = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)),
          match.numberOfRanges > 1,
          let range = Range(match.range(at: 1), in: value) else {
        return nil
    }

    return String(value[range])
        .replacingOccurrences(of: "&amp;", with: "&")
        .replacingOccurrences(of: "&quot;", with: "\"")
        .replacingOccurrences(of: "&#039;", with: "'")
        .replacingOccurrences(of: "&lt;", with: "<")
        .replacingOccurrences(of: "&gt;", with: ">")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

let blogTitle = firstMatch(#"<title>\s*(.*?)\s*</title>"#, in: html) ?? "Blog Roberta Matyszewskiego"
let blogDescription = firstMatch(#"<meta\s+name="description"\s+content="([^"]+)""#, in: html)
    ?? "AI, produkty i sprzedaż oprogramowania"
let shortDescription = blogDescription.contains("AI, produktach, sprzedaży oprogramowania")
    ? "AI, produkty i sprzedaż oprogramowania"
    : blogDescription
        .replacingOccurrences(of: "Notatki Roberta Matyszewskiego o ", with: "")
        .replacingOccurrences(of: " i budowaniu lokalnego ekosystemu technologicznego.", with: "")

func titleLines(_ title: String) -> [String] {
    let words = title.split(separator: " ").map(String.init)
    var lines: [String] = []
    var current = ""

    for word in words {
        let candidate = current.isEmpty ? word : "\(current) \(word)"

        if candidate.count <= 18 || current.isEmpty {
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

let lines = titleLines(blogTitle)
let escapedTitleLines = lines
    .enumerated()
    .map { index, line in
        let y = 330 + (index * 88)
        let escaped = line
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return ##"  <text x="96" y="\##(y)" fill="#151515" font-family="Inter, Arial, sans-serif" font-size="76" font-weight="800">\##(escaped)</text>"##
    }
    .joined(separator: "\n")

let escapedDescription = shortDescription
    .replacingOccurrences(of: "&", with: "&amp;")
    .replacingOccurrences(of: "<", with: "&lt;")
    .replacingOccurrences(of: ">", with: "&gt;")

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
  <text x="96" y="236" fill="#1f6b4a" font-family="Inter, Arial, sans-serif" font-size="26" font-weight="800" letter-spacing="3">BLOG</text>
\(escapedTitleLines)
  <rect x="96" y="468" width="606" height="1" fill="#d8ddd6"/>
  <text x="96" y="516" fill="#303330" font-family="Inter, Arial, sans-serif" font-size="30" font-weight="600">\(escapedDescription)</text>
  <text x="96" y="546" fill="#5e625f" font-family="Inter, Arial, sans-serif" font-size="24" font-weight="600">matyszewski.co/blog</text>
  <circle cx="1007" cy="174" r="42" fill="#d8b23f"/>
  <circle cx="1059" cy="230" r="30" fill="#285f9f"/>
  <circle cx="1000" cy="277" r="22" fill="#a9412f"/>
</svg>
"""

try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
try svg.write(to: outputSvg, atomically: true, encoding: .utf8)

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
if context.cgContext.width != Int(width) || context.cgContext.height != Int(height) {
    fatalError("Could not create graphics context")
}

func color(_ hex: UInt32, _ alpha: CGFloat = 1.0) -> NSColor {
    NSColor(
        calibratedRed: CGFloat((hex >> 16) & 0xff) / 255.0,
        green: CGFloat((hex >> 8) & 0xff) / 255.0,
        blue: CGFloat(hex & 0xff) / 255.0,
        alpha: alpha
    )
}

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

drawText("BLOG", x: 96, top: 214, w: 240, h: 34, size: 26, weight: .heavy, fill: color(0x1f6b4a), spacing: 3)
for (index, line) in lines.enumerated() {
    drawText(line, x: 96, top: CGFloat(276 + (index * 88)), w: 880, h: 86, size: 76, weight: .heavy, fill: color(0x151515))
}

color(0xd8ddd6).setStroke()
let divider = NSBezierPath()
divider.move(to: NSPoint(x: 96, y: topY(468, 1)))
divider.line(to: NSPoint(x: 702, y: topY(468, 1)))
divider.lineWidth = 1
divider.stroke()

drawText(shortDescription, x: 96, top: 488, w: 760, h: 42, size: 30, weight: .semibold, fill: color(0x303330))
drawText("matyszewski.co/blog", x: 96, top: 521, w: 360, h: 32, size: 24, weight: .semibold, fill: color(0x5e625f))

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

try png.write(to: outputPng)
