import Foundation
import CoreGraphics
import ImageIO

private struct CopyTestFailure: Error { let message: String }

@main
struct PDFImageCopyTests {
    static var checks = 0
    static let rgb = Data([255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0])

    static func main() throws {
        setbuf(stdout, nil)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("LumaViewPDFCopy-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let multiple = try fixture(root, "multiple", content: "q 80 0 0 60 10 20 cm /Im Do Q q 50 0 0 30 120 20 cm /Im Do Q")
        let index = try PDFImageCopy(url: multiple, pageIndex: 0)
        try check(index.pageSize == CGSize(width: 200, height: 160), "page size uses original PDF points")
        let first = try require(index.image(at: CGPoint(x: 30, y: 40)))
        try check(first.bounds == CGRect(x: 10, y: 20, width: 80, height: 60), "first embedded image has its exact independent bounds")
        try check(first.pixelSize == CGSize(width: 2, height: 2), "selection records original image sample dimensions")
        try check(index.image(at: CGPoint(x: 100, y: 100)) == nil, "page background does not become a full-page image selection")
        try check(index.image(at: CGPoint(x: 125, y: 30))?.bounds == CGRect(x: 120, y: 20, width: 50, height: 30), "q/Q restores CTM between different images")
        try check(index.image(at: CGPoint(x: CGFloat.nan, y: 10)) == nil, "invalid pointer coordinates are ignored")
        try compareWithPDF(first, url: multiple, name: "original RGB extraction preserves visible orientation")

        let overlap = try fixture(root, "overlap", content: "q 80 0 0 60 10 20 cm /Im Do Q q 20 0 0 20 30 30 cm /Im Do Q")
        let overlapIndex = try PDFImageCopy(url: overlap, pageIndex: 0)
        try check(overlapIndex.image(at: CGPoint(x: 35, y: 35))?.bounds == CGRect(x: 30, y: 30, width: 20, height: 20), "overlapping images select the last painted image")

        let clipped = try fixture(root, "clipped", content: "q 10 20 40 60 re W n 80 0 0 60 10 20 cm /Im Do Q")
        let clippedIndex = try PDFImageCopy(url: clipped, pageIndex: 0)
        try check(clippedIndex.image(at: CGPoint(x: 70, y: 50)) == nil, "clipped-away image content cannot be copied by clicking outside it")
        let clippedImage = try require(clippedIndex.image(at: CGPoint(x: 30, y: 50)))
        try check(clippedImage.bounds == CGRect(x: 10, y: 20, width: 40, height: 60), "clip reduces the exported image region")
        try compareWithPDF(clippedImage, url: clipped, name: "clipped extraction matches the visible image")

        let hole = try fixture(root, "clip-hole", content: "q 10 20 80 60 re 30 30 20 20 re W* n 80 0 0 60 10 20 cm /Im Do Q")
        let holeIndex = try PDFImageCopy(url: hole, pageIndex: 0)
        try check(holeIndex.image(at: CGPoint(x: 35, y: 35)) == nil, "even-odd clipping holes do not claim hidden image pixels")
        let holeImage = try require(holeIndex.image(at: CGPoint(x: 15, y: 25)))
        try check(holeImage.bounds == CGRect(x: 10, y: 20, width: 80, height: 60), "visible portion around a clip hole remains selectable")

        let cropRotate = try fixture(root, "cropped-rotated", content: "q 80 0 0 60 10 20 cm /Im Do Q", crop: "[10 20 110 140]", rotation: 90)
        let cropIndex = try PDFImageCopy(url: cropRotate, pageIndex: 0)
        try check(cropIndex.pageSize == CGSize(width: 120, height: 100), "crop box plus PDF rotation uses the same oriented page space as viewer")
        let rotatedSelection = try require(cropIndex.image(at: CGPoint(x: 30, y: 60)))
        try check(rotatedSelection.bounds == CGRect(x: 0, y: 20, width: 60, height: 80), "rotated image hit test follows oriented crop coordinates")
        try compareWithPDF(rotatedSelection, url: cropRotate, name: "cropped rotated PDF preserves image pose in copied bitmap")

        let transforms: [(String, String, CGPoint)] = [
            ("flip", "-80 0 0 60 90 20", CGPoint(x: 30, y: 50)),
            ("quarter-turn", "0 80 -60 0 100 20", CGPoint(x: 70, y: 50)),
            ("skew", "80 20 10 60 10 20", CGPoint(x: 50, y: 50))
        ]
        for (name, matrix, point) in transforms {
            let url = try fixture(root, name, content: "q \(matrix) cm /Im Do Q")
            let selection = try require(PDFImageCopy(url: url, pageIndex: 0).image(at: point))
            try compareWithPDF(selection, url: url, name: "\(name) image CTM is retained during copy")
        }

        let nested = try fixture(root, "nested", content: "q 1 0 0 1 10 15 cm /Outer Do Q",
                                 extraResources: "/Outer 6 0 R", extraObjects: [
            stream("/Type /XObject /Subtype /Form /BBox [0 0 120 100] /Matrix [1 0 0 1 20 10] /Resources << /XObject << /Inner 7 0 R >> >>", Data("/Inner Do".utf8)),
            stream("/Type /XObject /Subtype /Form /BBox [0 0 80 60] /Matrix [1 0 0 1 5 5] /Resources << /XObject << /Im 5 0 R >> >>", Data("q 80 0 0 60 0 0 cm /Im Do Q".utf8))
        ])
        let nestedSelection = try require(PDFImageCopy(url: nested, pageIndex: 0).image(at: CGPoint(x: 45, y: 40)))
        try check(nestedSelection.bounds == CGRect(x: 35, y: 30, width: 80, height: 60), "nested Form resources and matrices accumulate in drawing order")
        try compareWithPDF(nestedSelection, url: nested, name: "nested Form image copies original pixels in visible pose")

        let inherited = try fixture(root, "inherited", content: "/Outer Do", extraResources: "/Outer 6 0 R", extraObjects: [
            stream("/Type /XObject /Subtype /Form /BBox [0 0 70 60]", Data("q 80 0 0 60 10 20 cm /Im Do Q".utf8))
        ])
        let inheritedIndex = try PDFImageCopy(url: inherited, pageIndex: 0)
        try check(inheritedIndex.image(at: CGPoint(x: 30, y: 40))?.bounds == CGRect(x: 10, y: 20, width: 60, height: 40), "Form inherits missing resources and clips at BBox")
        try check(inheritedIndex.image(at: CGPoint(x: 80, y: 50)) == nil, "Form BBox excludes invisible image edges")

        let inverted = try fixture(root, "decode", content: "q 80 0 0 60 10 20 cm /Im Do Q", imageExtra: "/Decode [1 0 1 0 1 0]")
        try compareWithPDF(try require(PDFImageCopy(url: inverted, pageIndex: 0).image(at: CGPoint(x: 20, y: 30))),
                           url: inverted, name: "PDF Decode arrays use accurate renderer fallback")
        let skewInverted = try fixture(root, "skew-decode", content: "q 80 20 10 60 10 20 cm /Im Do Q", imageExtra: "/Decode [1 0 1 0 1 0]")
        try compareWithPDF(try require(PDFImageCopy(url: skewInverted, pageIndex: 0).image(at: CGPoint(x: 50, y: 50))),
                           url: skewInverted, name: "rotated renderer fallback keeps original edge coverage")

        let masked = try fixture(root, "soft-mask", content: "q 80 0 0 60 10 20 cm /Im Do Q", imageExtra: "/SMask 6 0 R", extraObjects: [
            stream("/Type /XObject /Subtype /Image /Width 2 /Height 2 /ColorSpace /DeviceGray /BitsPerComponent 8", Data([255, 128, 128, 0]))
        ])
        try compareWithPDF(try require(PDFImageCopy(url: masked, pageIndex: 0).image(at: CGPoint(x: 20, y: 30))),
                           url: masked, name: "soft-mask image retains visible alpha")

        let encoded = NSMutableData()
        let destination = CGImageDestinationCreateWithData(encoded, "public.jpeg" as CFString, 1, nil)!
        let provider = CGDataProvider(data: rgb as CFData)!
        let image = CGImage(width: 2, height: 2, bitsPerComponent: 8, bitsPerPixel: 24, bytesPerRow: 6,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: [], provider: provider,
                            decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 1] as CFDictionary)
        try check(CGImageDestinationFinalize(destination), "JPEG image fixture encoded")
        let jpeg = try fixture(root, "jpeg", content: "q -80 0 0 60 90 20 cm /Im Do Q", imageExtra: "/Filter /DCTDecode", imageData: encoded as Data)
        try compareWithPDF(try require(PDFImageCopy(url: jpeg, pageIndex: 0).image(at: CGPoint(x: 20, y: 30))),
                           url: jpeg, name: "JPEG source is decoded with original size and PDF flip")

        let inlineData = Data("q 80 0 0 60 10 20 cm BI /W 2 /H 2 /BPC 8 /CS /RGB ID ".utf8) + rgb + Data(" EI Q".utf8)
        let inline = try fixture(root, "inline", contentData: inlineData)
        let inlineSelection = try require(PDFImageCopy(url: inline, pageIndex: 0).image(at: CGPoint(x: 30, y: 40)))
        try compareWithPDF(inlineSelection, url: inline, name: "inline image remains copyable after scanner has been released")

        let recursive = try fixture(root, "cycle", content: "/Outer Do q 80 0 0 60 10 20 cm /Im Do Q", extraResources: "/Outer 6 0 R", extraObjects: [
            stream("/Type /XObject /Subtype /Form /BBox [0 0 100 100] /Resources << /XObject << /Outer 6 0 R >> >>", Data("/Outer Do".utf8))
        ])
        try check(try PDFImageCopy(url: recursive, pageIndex: 0).image(at: CGPoint(x: 30, y: 40)) != nil, "cyclic Form resources terminate without losing following valid images")

        let blank = try fixture(root, "blank", content: "1 0 0 rg 10 10 80 60 re f")
        try check(try PDFImageCopy(url: blank, pageIndex: 0).image(at: CGPoint(x: 30, y: 40)) == nil, "vector shapes are not mislabeled as embedded images")
        let badResource = try fixture(root, "bad-resource", content: "/Missing Do q 0 0 0 0 0 0 cm /Im Do Q")
        try check(try PDFImageCopy(url: badResource, pageIndex: 0).image(at: CGPoint(x: 30, y: 40)) == nil, "missing resources and singular matrices fail safely")
        let tooMany = try fixture(root, "operator-budget", content: String(repeating: "q Q ", count: 100_001) + "q 80 0 0 60 10 20 cm /Im Do Q")
        let budgetStart = ProcessInfo.processInfo.systemUptime
        try check(try PDFImageCopy(url: tooMany, pageIndex: 0).image(at: CGPoint(x: 30, y: 40)) == nil, "operator budget rejects incomplete image indexes")
        try check(ProcessInfo.processInfo.systemUptime - budgetStart < 5, "complex content stream stops within bounded scan time")
        do { _ = try PDFImageCopy(url: multiple, pageIndex: -1); try check(false, "negative page rejected") }
        catch PDFImageCopy.Failure.invalidDocument { try check(true, "negative page rejected") }
        do { _ = try PDFImageCopy(url: multiple, pageIndex: 1); try check(false, "out-of-range page rejected") }
        catch PDFImageCopy.Failure.invalidDocument { try check(true, "out-of-range page rejected") }

        let small = try first.render(maxPixelDimension: 1)
        try check(small.width == 1 && small.height == 1, "caller output bound is applied before bitmap allocation")
        try check(small.alphaInfo == .premultipliedLast && small.bitsPerPixel == 32, "copy bitmap is RGBA for PNG and TIFF pasteboard formats")
        let ai = root.appendingPathComponent("compatible.ai")
        try Data(contentsOf: multiple).write(to: ai)
        try check(try PDFImageCopy(url: ai, pageIndex: 0).image(at: CGPoint(x: 30, y: 40)) != nil, "PDF-compatible Illustrator uses the same image-copy support")
        print("PASS \(checks) PDF embedded image copy checks")
    }

    static func require(_ selection: PDFImageCopy.Selection?) throws -> PDFImageCopy.Selection {
        guard let selection else { throw CopyTestFailure(message: "expected an embedded image at fixture coordinate") }
        return selection
    }
    static func check(_ ok: Bool, _ name: String) throws {
        checks += 1
        print("\(ok ? "PASS" : "FAIL") \(name)")
        if !ok { throw CopyTestFailure(message: name) }
    }
    static func stream(_ dictionary: String, _ contents: Data) -> Data {
        Data("<< \(dictionary) /Length \(contents.count) >>\nstream\n".utf8) + contents + Data("\nendstream".utf8)
    }
    static func fixture(_ root: URL, _ name: String, content: String = "", contentData: Data? = nil,
                        crop: String = "[0 0 200 160]", rotation: Int = 0, imageExtra: String = "",
                        extraResources: String = "", extraObjects: [Data] = [], imageData: Data? = nil) throws -> URL {
        let objects: [Data] = [
            Data("<< /Type /Catalog /Pages 2 0 R >>".utf8),
            Data("<< /Type /Pages /Kids [3 0 R] /Count 1 >>".utf8),
            Data("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 160] /CropBox \(crop) /Rotate \(rotation) /Resources << /XObject << /Im 5 0 R \(extraResources) >> >> /Contents 4 0 R >>".utf8),
            stream("", contentData ?? Data(content.utf8)),
            stream("/Type /XObject /Subtype /Image /Width 2 /Height 2 /ColorSpace /DeviceRGB /BitsPerComponent 8 \(imageExtra)", imageData ?? rgb)
        ] + extraObjects
        var data = Data("%PDF-1.7\n".utf8), offsets = [0]
        for (i, object) in objects.enumerated() {
            offsets.append(data.count)
            data += Data("\(i + 1) 0 obj\n".utf8) + object + Data("\nendobj\n".utf8)
        }
        let xref = data.count
        data += Data("xref\n0 \(objects.count + 1)\n0000000000 65535 f \n".utf8)
        for offset in offsets.dropFirst() { data += Data(String(format: "%010d 00000 n \n", offset).utf8) }
        data += Data("trailer\n<< /Size \(objects.count + 1) /Root 1 0 R >>\nstartxref\n\(xref)\n%%EOF".utf8)
        let url = root.appendingPathComponent("\(name).pdf")
        try data.write(to: url)
        return url
    }
    static func compareWithPDF(_ selection: PDFImageCopy.Selection, url: URL, name: String) throws {
        let actual = try selection.render()
        let document = CGPDFDocument(url as CFURL)!, page = document.page(at: 1)!
        let crop = page.getBoxRect(.cropBox)
        let rotation = ((page.rotationAngle % 360) + 360) % 360
        let size = rotation == 90 || rotation == 270 ? CGSize(width: crop.height, height: crop.width) : crop.size
        let context = CGContext(data: nil, width: actual.width, height: actual.height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.scaleBy(x: CGFloat(actual.width) / selection.bounds.width, y: CGFloat(actual.height) / selection.bounds.height)
        context.translateBy(x: -selection.bounds.minX, y: -selection.bounds.minY)
        context.concatenate(page.getDrawingTransform(.cropBox, rect: CGRect(origin: .zero, size: size), rotate: 0, preserveAspectRatio: true))
        context.interpolationQuality = .high
        context.drawPDFPage(page)
        let expected = context.makeImage()!
        let lhs = pixels(actual), rhs = pixels(expected)
        let maxDifference = zip(lhs, rhs).map { abs(Int($0) - Int($1)) }.max() ?? 0
        if maxDifference > 18 { print("actual", lhs, "expected", rhs) }
        try check(maxDifference <= 18, "\(name) (maximum sample difference \(maxDifference))")
    }
    static func pixels(_ image: CGImage) -> [UInt8] {
        let c = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width * 4,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        c.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return Array(UnsafeBufferPointer(start: c.data!.assumingMemoryBound(to: UInt8.self), count: image.width * image.height * 4))
    }
}
