import AppKit
import CryptoKit

private struct Failure: Error { let text: String }
private final class Operators { var paths = 0; var text = 0; var images = 0 }

@main
struct PostScriptTests {
    static var checks = 0
    static func check(_ ok: @autoclosure () throws -> Bool, _ text: String) throws {
        guard try ok() else { throw Failure(text: text) }
        checks += 1; print("PASS \(text)")
    }
    static func main() throws {
        setbuf(stdout, nil); _ = NSApplication.shared
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("LumaViewPostScript-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = root.appendingPathComponent("cache")
        let eps = root.appendingPathComponent("space 中文 ; $ test.eps")
        let drawing = """
        %!PS-Adobe-3.0 EPSF-3.0
        %%BoundingBox: 10 20 210 120
        1 0 0 setrgbcolor 10 20 200 100 rectfill
        0 0 1 setrgbcolor 20 30 moveto 40 100 100 40 190 100 curveto 2 setlinewidth stroke
        /Helvetica findfont 18 scalefont setfont 30 60 moveto (Vector preview) show
        showpage
        %%EOF
        """
        try Data(drawing.utf8).write(to: eps)
        let pdf = try PostScriptDocument.convert(url: eps, cacheDirectory: cache)
        let doc = try requirePDF(pdf)
        try check(doc.numberOfPages == 1 && doc.page(at: 1)!.getBoxRect(.mediaBox).size == CGSize(width: 200, height: 100), "EPS crop preserves nonzero bounding box")
        let operators = scan(doc.page(at: 1)!)
        try check(operators.paths > 0 && operators.text > 0 && operators.images == 0, "EPS output retains paths and text without whole-page rasterization")
        try check(try PostScriptDocument.convert(url: eps, cacheDirectory: cache) == pdf, "unchanged source reuses completed cache")
        let live = try DocumentMedia(url: eps)
        let page = try live.page(at: 0)
        try check(live.isVector && page.rasterImage == nil && live.format == "EPS", "main canvas receives original vector page representation")
        let zoom = try page.preview(maxPixelDimension: 2400)
        try check(zoom.width == 2400 && zoom.height == 1200, "large zoom redraws vector geometry")
        let thumb = try VectorRenderer.render(url: eps, maxPixelDimension: 128)
        try check(thumb.image.width == 128 && thumb.image.height == 64 && thumb.format == "PostScript", "filmstrip uses full PostScript drawing")
        try png(zoom, output.appendingPathComponent("vector-eps-zoom.png"))
        try Data(drawing.replacingOccurrences(of: "1 0 0 setrgbcolor", with: "0 1 0 setrgbcolor").utf8).write(to: eps)
        let revised = try PostScriptDocument.convert(url: eps, cacheDirectory: cache)
        try check(revised != pdf, "same-path changed source invalidates cache")
        let ps = root.appendingPathComponent("multipage.ps")
        try Data("%!PS-Adobe-3.0\n<< /PageSize [180 90] >> setpagedevice\n1 0 0 setrgbcolor 0 0 180 90 rectfill showpage\n0 0 1 setrgbcolor 0 0 180 90 rectfill showpage\n".utf8).write(to: ps)
        let multi = try DocumentMedia(url: ps)
        try check(multi.pageCount == 2 && multi.isVector && multi.format == "PostScript", "PostScript multiple pages use existing page navigation")
        try check(try multi.page(at: 1).size == CGSize(width: 180, height: 90), "PostScript page geometry remains intact")
        let ai = root.appendingPathComponent("old-illustrator.ai")
        try Data(drawing.utf8).write(to: ai)
        try check(try DocumentMedia(url: ai).isVector, "legacy PostScript Illustrator file receives vector preview")
        let malformed = root.appendingPathComponent("bad.eps")
        try Data([0xC5, 0xD0, 0xD3, 0xC6] + Array(repeating: 255, count: 28)).write(to: malformed)
        try expectFailure("malformed DOS EPS offsets rejected") { _ = try PostScriptDocument.convert(url: malformed, cacheDirectory: cache) }
        let invalid = root.appendingPathComponent("invalid.ps")
        try Data("%!PS\nthisIsNotAnOperator showpage\n".utf8).write(to: invalid)
        try expectFailure("interpreter error never publishes invalid cache") { _ = try PostScriptDocument.convert(url: invalid, cacheDirectory: cache) }
        let infinite = root.appendingPathComponent("infinite.ps")
        try Data("%!PS\n{} loop\n".utf8).write(to: infinite)
        let start = Date()
        do { _ = try PostScriptDocument.convert(url: infinite, cacheDirectory: cache, timeout: 0.3); throw Failure(text: "timeout missing") }
        catch PostScriptDocument.Failure.timedOut { try check(Date().timeIntervalSince(start) < 4, "infinite PostScript bounded by interpreter timeout") }
        let request = ThumbnailRequest()
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.15) { request.cancel() }
        let cancelStart = Date()
        do { _ = try PostScriptDocument.convert(url: infinite, request: request, cacheDirectory: cache); throw Failure(text: "cancel missing") }
        catch is CancellationError { try check(Date().timeIntervalSince(cancelStart) < 3, "file switching promptly cancels its interpreter") }
        Thread.sleep(forTimeInterval: 0.2)
        try check(try FileManager.default.contentsOfDirectory(at: cache, includingPropertiesForKeys: nil).allSatisfy { !$0.lastPathComponent.hasPrefix(".job-") }, "cancelled and failed jobs clean private scratch directories")
        let secret = root.appendingPathComponent("private.txt")
        try Data("do not read".utf8).write(to: secret)
        let escaped = secret.path.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "(", with: "\\(").replacingOccurrences(of: ")", with: "\\)")
        for (name, code) in [("read", "(\(escaped)) (r) file closefile"), ("write", "(\(escaped)) (w) file closefile"), ("pipe", "(%pipe%/usr/bin/true) (r) file closefile")] {
            let attack = root.appendingPathComponent("denied-\(name).ps")
            try Data("%!PS\n\(code)\nshowpage\n".utf8).write(to: attack)
            try expectFailure("PostScript \(name) outside allowlist is denied") { _ = try PostScriptDocument.convert(url: attack, cacheDirectory: cache) }
        }
        try check(try String(contentsOf: secret) == "do not read", "interpreter leaves external files unchanged")
        try concurrency(source: ai, root: root)
        for argument in CommandLine.arguments.dropFirst(2) {
            let original = URL(fileURLWithPath: argument)
            let before = SHA256.hash(data: try Data(contentsOf: original))
            let converted = try PostScriptDocument.convert(url: original, cacheDirectory: cache)
            let full = try requirePDF(converted)
            let counts = scan(full.page(at: 1)!)
            try check(counts.paths > 0 && counts.text > 0, "user EPS retains actual vector paths and text")
            let document = try DocumentMedia(url: original)
            try check(document.isVector && document.format == "EPS", "user EPS uses vector source instead of embedded TIFF")
            try png(try document.page(at: 0).preview(maxPixelDimension: 2000), output.appendingPathComponent("attachment-eps-vector.png"))
            try check(SHA256.hash(data: try Data(contentsOf: original)) == before, "user original bytes remain unchanged")
            print("EPS operators: paths=\(counts.paths), text=\(counts.text), images=\(counts.images)")
        }
        print("\(checks) PostScript checks passed.")
    }
    static func concurrency(source: URL, root: URL) throws {
        let sharedCache = root.appendingPathComponent("shared-cache")
        let group = DispatchGroup(), lock = NSLock()
        var outputs: [URL] = [], failures: [Error] = []
        let abandoned = ThumbnailRequest()
        for index in 0..<8 {
            group.enter()
            DispatchQueue.global().async {
                defer { group.leave() }
                do {
                    let value = try PostScriptDocument.convert(url: source, request: index == 0 ? abandoned : nil, cacheDirectory: sharedCache)
                    lock.lock(); outputs.append(value); lock.unlock()
                } catch { lock.lock(); failures.append(error); lock.unlock() }
            }
        }
        abandoned.cancel(); group.wait()
        try check(outputs.count >= 7 && Set(outputs).count == 1 && failures.allSatisfy { $0 is CancellationError }, "shared main/thumbnail consumers deduplicate without cross-cancellation")
        try check(try FileManager.default.contentsOfDirectory(at: sharedCache, includingPropertiesForKeys: nil).filter { $0.pathExtension == "pdf" }.count == 1, "concurrent requests publish exactly one completed cache file")
    }
    static func expectFailure(_ text: String, _ action: () throws -> Void) throws {
        do { try action(); throw Failure(text: text) }
        catch let error as Failure { throw error }
        catch { try check(true, text) }
    }
    static func requirePDF(_ url: URL) throws -> CGPDFDocument {
        guard let document = CGPDFDocument(url as CFURL) else { throw Failure(text: "missing PDF") }; return document
    }
    private static func scan(_ page: CGPDFPage) -> Operators {
        let counts = Operators(), table = CGPDFOperatorTableCreate()!
        for name in ["m", "l", "c", "re", "sh"] {
            CGPDFOperatorTableSetCallback(table, name) { _, pointer in Unmanaged<Operators>.fromOpaque(pointer!).takeUnretainedValue().paths += 1 }
        }
        for name in ["Tj", "TJ", "'", "\""] {
            CGPDFOperatorTableSetCallback(table, name) { _, pointer in Unmanaged<Operators>.fromOpaque(pointer!).takeUnretainedValue().text += 1 }
        }
        CGPDFOperatorTableSetCallback(table, "Do") { _, pointer in Unmanaged<Operators>.fromOpaque(pointer!).takeUnretainedValue().images += 1 }
        let stream = CGPDFContentStreamCreateWithPage(page)
        let scanner = CGPDFScannerCreate(stream, table, Unmanaged.passUnretained(counts).toOpaque())
        withExtendedLifetime(counts) { _ = CGPDFScannerScan(scanner) }
        return counts
    }
    static func png(_ image: CGImage, _ url: URL) throws {
        let bitmap = NSBitmapImageRep(cgImage: image)
        try bitmap.representation(using: .png, properties: [:])!.write(to: url)
    }
}
