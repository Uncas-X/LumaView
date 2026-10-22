import AppKit
import Foundation

// Original vector artwork, drawn locally at each macOS icon resolution.
let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "LumaView.iconset"
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)

func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: alpha)
}

func rounded(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func drawIcon(size: Int) throws -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                 bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                 isPlanar: false, colorSpaceName: .deviceRGB,
                                 bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!.cgContext
    context.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -17), blur: 25, color: color(0x473926, alpha: 0.18))
    context.addPath(rounded(CGRect(x: 72, y: 72, width: 880, height: 880), 198))
    context.setFillColor(color(0xF4EDE0))
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(rounded(CGRect(x: 72, y: 72, width: 880, height: 880), 198))
    context.clip()
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                              colors: [color(0xFFFDF5), color(0xEAE2D4)] as CFArray,
                              locations: [0, 1])!
    context.drawLinearGradient(gradient, start: CGPoint(x: 340, y: 940), end: CGPoint(x: 720, y: 85),
                               options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    context.restoreGState()

    // A quiet rear print gives the icon the silhouette of a small photo stack.
    context.saveGState()
    context.translateBy(x: 510, y: 520)
    context.rotate(by: -.pi / 13)
    context.setShadow(offset: CGSize(width: 0, height: -12), blur: 18, color: color(0x3C3025, alpha: 0.16))
    context.addPath(rounded(CGRect(x: -275, y: -258, width: 550, height: 538), 54))
    context.setFillColor(color(0xC4BCAF))
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -18), blur: 30, color: color(0x30261E, alpha: 0.25))
    context.addPath(rounded(CGRect(x: 240, y: 238, width: 560, height: 560), 66))
    context.setFillColor(color(0xFFFEF8))
    context.fillPath()
    context.restoreGState()
    context.addPath(rounded(CGRect(x: 275, y: 303, width: 490, height: 460), 35))
    context.setFillColor(color(0x302F2A))
    context.fillPath()

    // Six amber iris blades surround an ivory aperture opening.
    let center = CGPoint(x: 520, y: 533)
    let bladeColors: [UInt32] = [0xF4B955, 0xECA449, 0xE1943B, 0xD88632, 0xDE983F, 0xF0AD4D]
    for index in 0..<6 {
        let a = CGFloat(index) * .pi / 3
        func point(_ radius: CGFloat, _ angle: CGFloat) -> CGPoint {
            CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        }
        let path = CGMutablePath()
        path.move(to: point(190, a))
        path.addLine(to: point(190, a + .pi / 3))
        path.addLine(to: point(77, a + .pi / 3 + .pi / 6))
        path.addLine(to: point(77, a + .pi / 6))
        path.closeSubpath()
        context.addPath(path)
        context.setFillColor(color(bladeColors[index]))
        context.fillPath()
    }
    let opening = CGMutablePath()
    for index in 0..<6 {
        let angle = CGFloat(index) * .pi / 3 + .pi / 6
        let point = CGPoint(x: center.x + cos(angle) * 70, y: center.y + sin(angle) * 70)
        if index == 0 { opening.move(to: point) } else { opening.addLine(to: point) }
    }
    opening.closeSubpath()
    context.addPath(opening)
    context.setFillColor(color(0xFFF6DC))
    context.fillPath()

    return bitmap.representation(using: .png, properties: [:])!
}

for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let suffix = scale == 1 ? "" : "@2x"
        let name = "icon_\(base)x\(base)\(suffix).png"
        try drawIcon(size: base * scale).write(to: URL(fileURLWithPath: output).appendingPathComponent(name))
    }
}
print("Generated icon artwork: \(output)")

// Some restricted macOS environments cannot run iconutil's encoder. Modern
// ICNS stores these PNG representations in a simple, documented chunk container.
if CommandLine.arguments.count > 2 {
    func bigEndianBytes(_ number: Int) -> Data {
        var value = UInt32(number).bigEndian
        return withUnsafeBytes(of: &value) { Data($0) }
    }
    let entries = [
        ("icp4", "icon_16x16.png"), ("ic11", "icon_16x16@2x.png"),
        ("icp5", "icon_32x32.png"), ("ic12", "icon_32x32@2x.png"),
        ("ic07", "icon_128x128.png"), ("ic13", "icon_128x128@2x.png"),
        ("ic08", "icon_256x256.png"), ("ic14", "icon_256x256@2x.png"),
        ("ic09", "icon_512x512.png"), ("ic10", "icon_512x512@2x.png")
    ]
    var body = Data()
    for (kind, filename) in entries {
        let png = try Data(contentsOf: URL(fileURLWithPath: output).appendingPathComponent(filename))
        body.append(Data(kind.utf8))
        body.append(bigEndianBytes(png.count + 8))
        body.append(png)
    }
    var icon = Data("icns".utf8)
    icon.append(bigEndianBytes(body.count + 8))
    icon.append(body)
    try icon.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
    print("Generated ICNS: \(CommandLine.arguments[2])")
}
