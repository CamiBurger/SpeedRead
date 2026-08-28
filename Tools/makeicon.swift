// Renders SpeedRead's app icon: a zooming 🐇 with speed lines on a gradient squircle.
// Usage: swift Tools/makeicon.swift
import AppKit

let outDir = "Resources/Assets.xcassets/AppIcon.appiconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func render(size S: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext

    // macOS icon grid: rounded square inset from the canvas edge.
    let inset = S * 0.098
    let rect = CGRect(x: inset, y: inset, width: S - inset * 2, height: S - inset * 2)
    let radius = rect.width * 0.2237
    let squircle = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    // Gradient background (blue -> violet, top-left to bottom-right).
    ctx.saveGState()
    squircle.addClip()
    let gradient = NSGradient(colors: [
        NSColor(srgbRed: 0.36, green: 0.55, blue: 0.98, alpha: 1),
        NSColor(srgbRed: 0.61, green: 0.36, blue: 0.96, alpha: 1),
    ])!
    gradient.draw(in: rect, angle: -45)

    // Speed lines trailing behind the rabbit.
    NSColor(white: 1, alpha: 0.85).setFill()
    let lineH = rect.height * 0.052
    let lines: [(cx: CGFloat, y: CGFloat, w: CGFloat)] = [
        (0.40, 0.64, 0.50),
        (0.34, 0.52, 0.44),
        (0.40, 0.40, 0.36),
    ]
    for l in lines {
        let w = rect.width * l.w
        let x = rect.minX + rect.width * l.cx - w
        let y = rect.minY + rect.height * l.y - lineH / 2
        let cap = NSBezierPath(roundedRect: CGRect(x: x, y: y, width: w, height: lineH),
                               xRadius: lineH / 2, yRadius: lineH / 2)
        NSColor(white: 1, alpha: 0.28 + 0.14 * l.w).setFill()
        cap.fill()
    }
    ctx.restoreGState()

    // The rabbit, nudged toward the leading (right) edge, tilted forward.
    let glyphSize = rect.height * 0.58
    let str = "🐇" as NSString
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: glyphSize)]
    let bounds = str.size(withAttributes: attrs)

    ctx.saveGState()
    let anchorX = rect.minX + rect.width * 0.50
    let anchorY = rect.minY + rect.height * 0.50
    ctx.translateBy(x: anchorX, y: anchorY)
    ctx.scaleBy(x: -1, y: 1)          // mirror 🐇 so it faces right (direction of motion)
    ctx.rotate(by: -8 * .pi / 180)
    // Soft shadow for depth.
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(white: 0, alpha: 0.22)
    shadow.shadowBlurRadius = S * 0.02
    shadow.shadowOffset = NSSize(width: 0, height: -S * 0.012)
    shadow.set()
    str.draw(at: CGPoint(x: -bounds.width / 2, y: -bounds.height / 2), withAttributes: attrs)
    ctx.restoreGState()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func write(_ rep: NSBitmapImageRep, _ name: String) {
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
}

// macOS AppIcon: pt sizes at @1x and @2x.
let specs: [(pt: Int, scales: [Int])] = [
    (16, [1, 2]), (32, [1, 2]), (128, [1, 2]), (256, [1, 2]), (512, [1, 2]),
]
var images: [[String: String]] = []
for spec in specs {
    for scale in spec.scales {
        let px = spec.pt * scale
        let file = "icon_\(spec.pt)x\(spec.pt)@\(scale)x.png"
        write(render(size: CGFloat(px)), file)
        images.append([
            "size": "\(spec.pt)x\(spec.pt)",
            "idiom": "mac",
            "filename": file,
            "scale": "\(scale)x",
        ])
    }
}

let contents: [String: Any] = [
    "images": images,
    "info": ["version": 1, "author": "xcode"],
]
let json = try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try! json.write(to: URL(fileURLWithPath: "\(outDir)/Contents.json"))
print("wrote \(images.count) icon images to \(outDir)")
