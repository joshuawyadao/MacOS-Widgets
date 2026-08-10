import AppKit
import Foundation

struct FontPreview {
    let assetName: String
    let font: (CGFloat) -> NSFont
}

func systemFont(size: CGFloat, weight: NSFont.Weight, design: NSFontDescriptor.SystemDesign) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    guard let descriptor = base.fontDescriptor.withDesign(design) else { return base }
    return NSFont(descriptor: descriptor, size: size) ?? base
}

func namedFont(_ name: String, size: CGFloat) -> NSFont {
    NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size, weight: .bold)
}

let previews = [
    FontPreview(assetName: "FontPreviewSystemBold") {
        NSFont.systemFont(ofSize: $0, weight: .black)
    },
    FontPreview(assetName: "FontPreviewSystemRounded") {
        systemFont(size: $0, weight: .heavy, design: .rounded)
    },
    FontPreview(assetName: "FontPreviewSystemSerif") {
        systemFont(size: $0, weight: .bold, design: .serif)
    },
    FontPreview(assetName: "FontPreviewSystemMonospaced") {
        NSFont.monospacedSystemFont(ofSize: $0, weight: .bold)
    },
    FontPreview(assetName: "FontPreviewAvenirNext") {
        namedFont("AvenirNext-Heavy", size: $0)
    },
    FontPreview(assetName: "FontPreviewNoteworthy") {
        namedFont("Noteworthy-Bold", size: $0)
    },
    FontPreview(assetName: "FontPreviewChalkboard") {
        namedFont("ChalkboardSE-Bold", size: $0)
    },
    FontPreview(assetName: "FontPreviewBradleyHand") {
        namedFont("BradleyHandITCTT-Bold", size: $0)
    },
    FontPreview(assetName: "FontPreviewMarkerFelt") {
        namedFont("MarkerFelt-Wide", size: $0)
    },
    FontPreview(assetName: "FontPreviewSnellRoundhand") {
        namedFont("SnellRoundhand-Bold", size: $0)
    },
]

guard let outputRoot = CommandLine.arguments.dropFirst().first else {
    fputs("Usage: swift Scripts/GenerateFontPreviews.swift <Assets.xcassets path>\n", stderr)
    exit(2)
}

func render(preview: FontPreview, scale: Int, outputURL: URL) throws {
    let side = 72 * scale
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: side,
        pixelsHigh: side,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw CocoaError(.fileWriteUnknown)
    }

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: side, height: side).fill()

    let font = preview.font(CGFloat(39 * scale))
    let text = "Aa" as NSString
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.black,
    ]
    let measured = text.size(withAttributes: attributes)
    let rect = NSRect(
        x: (CGFloat(side) - measured.width) / 2,
        y: (CGFloat(side) - measured.height) / 2,
        width: measured.width,
        height: measured.height
    )
    text.draw(in: rect, withAttributes: attributes)

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    try data.write(to: outputURL, options: .atomic)
}

let rootURL = URL(fileURLWithPath: outputRoot, isDirectory: true)
for preview in previews {
    let imageSetURL = rootURL.appendingPathComponent("\(preview.assetName).imageset", isDirectory: true)
    try FileManager.default.createDirectory(at: imageSetURL, withIntermediateDirectories: true)
    try render(
        preview: preview,
        scale: 1,
        outputURL: imageSetURL.appendingPathComponent("\(preview.assetName).png")
    )
    try render(
        preview: preview,
        scale: 2,
        outputURL: imageSetURL.appendingPathComponent("\(preview.assetName)@2x.png")
    )
}
