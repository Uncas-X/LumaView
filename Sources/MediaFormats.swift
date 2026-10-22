import Foundation
import UniformTypeIdentifiers

enum MediaCategory: String, CaseIterable {
    case image, vector, video, audio
    var title: String {
        switch self { case .image: return L10n.tr("图片"); case .vector: return L10n.tr("矢量 / 文档"); case .video: return L10n.tr("视频"); case .audio: return L10n.tr("音频") }
    }
}

struct MediaFormat {
    let id: String
    let sourceTitle: String
    var title: String { L10n.tr(sourceTitle) }
    init(id: String, title: String, extensions: [String], category: MediaCategory) {
        self.id = id; self.sourceTitle = title; self.extensions = extensions; self.category = category
    }
    let extensions: [String]
    let category: MediaCategory
    var associationTypes: [UTType] {
        var seen = Set<String>()
        return extensions.map { MediaFormats.associationType(for: $0, category: category) }
            .filter { seen.insert($0.identifier).inserted }
    }
}

/// Shared by discovery, the format picker and Launch Services declarations.
/// A container suffix identifies candidates; the decoder validates actual contents.
enum MediaFormats {
    /// Freeze the shipped extension-to-UTI choice alongside document declarations.
    /// A subsequently installed app must not silently change the picker's targets.
    private static let bundledAssociationIdentifiers = Bundle.main.object(forInfoDictionaryKey: "LumaViewFormatAssociations") as? [String: String] ?? [:]
    static let associationFormats: [MediaFormat] = [
        MediaFormat(id: "jpeg", title: "JPEG", extensions: ["jpg", "jpeg", "jpe", "jfif"], category: .image),
        MediaFormat(id: "png", title: "PNG / APNG", extensions: ["png", "apng"], category: .image),
        MediaFormat(id: "gif", title: "GIF", extensions: ["gif"], category: .image),
        MediaFormat(id: "tiff", title: "TIFF", extensions: ["tif", "tiff"], category: .image),
        MediaFormat(id: "bmp", title: "BMP", extensions: ["bmp", "dib"], category: .image),
        MediaFormat(id: "heif", title: "HEIF / HEIC", extensions: ["heic", "heif", "hif", "heics"], category: .image),
        MediaFormat(id: "webp", title: "WebP", extensions: ["webp"], category: .image),
        MediaFormat(id: "avif", title: "AVIF", extensions: ["avif"], category: .image),
        MediaFormat(id: "jxl", title: "JPEG XL", extensions: ["jxl"], category: .image),
        MediaFormat(id: "jp2", title: "JPEG 2000", extensions: ["jp2", "j2k", "jpf", "jpx", "j2c"], category: .image),
        MediaFormat(id: "icons", title: "图标", extensions: ["ico", "cur", "icns"], category: .image),
        MediaFormat(id: "psd", title: "Photoshop (PSD / PSB)", extensions: ["psd", "psb"], category: .image),
        MediaFormat(id: "tga", title: "Targa", extensions: ["tga"], category: .image),
        MediaFormat(id: "hdr", title: "HDR / OpenEXR", extensions: ["hdr", "exr"], category: .image),
        MediaFormat(id: "pnm", title: "Netpbm", extensions: ["pbm", "pgm", "ppm", "pfm"], category: .image),
        MediaFormat(id: "dng", title: "Adobe DNG", extensions: ["dng"], category: .image),
        MediaFormat(id: "canonraw", title: "Canon RAW", extensions: ["cr2", "cr3", "crw"], category: .image),
        MediaFormat(id: "nikonraw", title: "Nikon RAW", extensions: ["nef", "nrw"], category: .image),
        MediaFormat(id: "sonyraw", title: "Sony RAW", extensions: ["arw", "sr2", "srf"], category: .image),
        MediaFormat(id: "otherraw", title: "其他相机 RAW", extensions: ["orf", "raf", "rw2", "pef", "srw"], category: .image),
        MediaFormat(id: "svg", title: "SVG", extensions: ["svg"], category: .vector),
        MediaFormat(id: "pdf", title: "PDF", extensions: ["pdf"], category: .vector),
        MediaFormat(id: "ai", title: "Adobe Illustrator", extensions: ["ai"], category: .vector),
        MediaFormat(id: "eps", title: "EPS / PostScript", extensions: ["eps", "epsf", "ps"], category: .vector),
        MediaFormat(id: "mp4", title: "MPEG-4", extensions: ["mp4", "m4v"], category: .video),
        MediaFormat(id: "quicktime", title: "QuickTime", extensions: ["mov", "qt"], category: .video),
        MediaFormat(id: "matroska", title: "Matroska", extensions: ["mkv", "mk3d"], category: .video),
        MediaFormat(id: "webm", title: "WebM", extensions: ["webm"], category: .video),
        MediaFormat(id: "avi", title: "AVI", extensions: ["avi", "divx"], category: .video),
        MediaFormat(id: "flash", title: "Flash Video", extensions: ["flv", "f4v"], category: .video),
        MediaFormat(id: "windowsvideo", title: "Windows Media / ASF", extensions: ["wmv", "asf"], category: .video),
        MediaFormat(id: "mpeg", title: "MPEG Video", extensions: ["mpg", "mpeg", "mpe", "m1v", "m2v"], category: .video),
        MediaFormat(id: "transport", title: "MPEG Transport Stream", extensions: ["ts", "mts", "m2ts", "m2t", "m2p", "trp"], category: .video),
        MediaFormat(id: "3gp", title: "3GPP", extensions: ["3gp", "3gpp", "3g2"], category: .video),
        MediaFormat(id: "oggvideo", title: "Ogg Video", extensions: ["ogv", "ogm"], category: .video),
        MediaFormat(id: "realvideo", title: "RealVideo", extensions: ["rm", "rmvb"], category: .video),
        MediaFormat(id: "dvd", title: "DVD Video", extensions: ["vob"], category: .video),
        MediaFormat(id: "camcorder", title: "摄像机视频", extensions: ["mod", "tod"], category: .video),
        MediaFormat(id: "mjpeg", title: "Motion JPEG", extensions: ["mjpeg", "mjpg", "mj2"], category: .video),
        MediaFormat(id: "mxf", title: "MXF", extensions: ["mxf"], category: .video),
        MediaFormat(id: "dv", title: "DV", extensions: ["dv", "dif"], category: .video),
        MediaFormat(id: "nut", title: "NUT", extensions: ["nut"], category: .video),
        MediaFormat(id: "nsv", title: "Nullsoft Video", extensions: ["nsv"], category: .video),
        MediaFormat(id: "amv", title: "AMV", extensions: ["amv"], category: .video),
        MediaFormat(id: "bink", title: "Bink / Smacker", extensions: ["bik", "bk2", "smk"], category: .video),
        MediaFormat(id: "rawvideo", title: "视频码流", extensions: ["h264", "264", "avc", "h265", "265", "hevc", "h266", "vvc", "ivf", "y4m"], category: .video),
        MediaFormat(id: "mp3", title: "MP3 / MPEG Audio", extensions: ["mp3", "mp2", "mp1", "mpa"], category: .audio),
        MediaFormat(id: "aac", title: "AAC", extensions: ["aac", "adts"], category: .audio),
        MediaFormat(id: "appleaudio", title: "MPEG-4 Audio", extensions: ["m4a", "m4b", "m4r", "alac"], category: .audio),
        MediaFormat(id: "wav", title: "WAVE", extensions: ["wav", "wave", "bwf", "rf64"], category: .audio),
        MediaFormat(id: "aiff", title: "AIFF", extensions: ["aif", "aiff", "aifc"], category: .audio),
        MediaFormat(id: "caf", title: "Core Audio", extensions: ["caf"], category: .audio),
        MediaFormat(id: "flac", title: "FLAC", extensions: ["flac"], category: .audio),
        MediaFormat(id: "ogg", title: "Ogg / Vorbis", extensions: ["ogg", "oga"], category: .audio),
        MediaFormat(id: "opus", title: "Opus", extensions: ["opus"], category: .audio),
        MediaFormat(id: "speex", title: "Speex", extensions: ["spx", "speex"], category: .audio),
        MediaFormat(id: "ape", title: "Monkey’s Audio", extensions: ["ape"], category: .audio),
        MediaFormat(id: "wma", title: "Windows Media Audio", extensions: ["wma"], category: .audio),
        MediaFormat(id: "wavpack", title: "WavPack", extensions: ["wv"], category: .audio),
        MediaFormat(id: "tta", title: "True Audio", extensions: ["tta"], category: .audio),
        MediaFormat(id: "tak", title: "TAK", extensions: ["tak"], category: .audio),
        MediaFormat(id: "shorten", title: "Shorten", extensions: ["shn"], category: .audio),
        MediaFormat(id: "dolby", title: "Dolby Audio", extensions: ["ac3", "eac3", "ec3", "truehd", "thd", "mlp"], category: .audio),
        MediaFormat(id: "dts", title: "DTS", extensions: ["dts", "dtshd"], category: .audio),
        MediaFormat(id: "amr", title: "AMR", extensions: ["amr", "awb"], category: .audio),
        MediaFormat(id: "sun", title: "AU / SND", extensions: ["au", "snd"], category: .audio),
        MediaFormat(id: "realaudio", title: "RealAudio", extensions: ["ra"], category: .audio),
        MediaFormat(id: "dsd", title: "DSD", extensions: ["dsf", "dff", "dsd"], category: .audio),
        MediaFormat(id: "matroskaaudio", title: "Matroska Audio", extensions: ["mka"], category: .audio),
        MediaFormat(id: "musepack", title: "Musepack", extensions: ["mpc", "mpp", "mp+"], category: .audio),
        MediaFormat(id: "gsm", title: "GSM / QCP", extensions: ["gsm", "qcp"], category: .audio),
        MediaFormat(id: "iffaudio", title: "IFF Audio", extensions: ["8svx", "16sv"], category: .audio),
    ]
    static let videoExtensions = extensions(for: .video)
    static let audioExtensions = extensions(for: .audio)
    static let vectorExtensions = extensions(for: .vector)
    static let imageExtensions = extensions(for: .image)
    static func extensions(for category: MediaCategory) -> Set<String> {
        Set(associationFormats.filter { $0.category == category }.flatMap(\.extensions))
    }
    static func isAudio(_ url: URL) -> Bool { url.isFileURL && audioExtensions.contains(url.pathExtension.lowercased()) }
    static func isVideo(_ url: URL) -> Bool { url.isFileURL && videoExtensions.contains(url.pathExtension.lowercased()) }
    static func isVector(_ url: URL) -> Bool { url.isFileURL && vectorExtensions.contains(url.pathExtension.lowercased()) }
    static func importedIdentifier(for extensionName: String) -> String {
        "io.local.lumaview.format." + extensionName.lowercased().replacingOccurrences(of: "+", with: "plus")
    }
    static func associationType(for extensionName: String, category: MediaCategory) -> UTType {
        let parent: UTType
        switch category { case .audio: parent = .audio; case .video: parent = .movie; case .image: parent = .image; case .vector: parent = .image }
        if let identifier = bundledAssociationIdentifiers[extensionName.lowercased()],
           !forbiddenAssociationIdentifiers.contains(identifier) {
            let declared = UTType(identifier) ?? UTType(importedAs: identifier, conformingTo: parent)
            if isEligible(declared, for: category) { return declared }
        }
        // Development tools do not run inside the app bundle. Their generation
        // step validates these system results before writing the frozen map.
        if let known = UTType(filenameExtension: extensionName), isEligible(known, for: category) { return known }
        return UTType(importedAs: importedIdentifier(for: extensionName), conformingTo: parent)
    }
    private static func isEligible(_ type: UTType, for category: MediaCategory) -> Bool {
        guard !type.isDynamic, !forbiddenAssociationIdentifiers.contains(type.identifier) else { return false }
        switch category {
        case .image: return type.conforms(to: .image)
        case .video: return type.conforms(to: .movie) || type.conforms(to: .video)
        case .audio: return type.conforms(to: .audio)
        case .vector: return type.conforms(to: .image) || type.conforms(to: .pdf)
            || ["com.adobe.illustrator.ai-image", "com.adobe.encapsulated-postscript", "com.adobe.postscript"].contains(type.identifier)
        }
    }
    static let forbiddenAssociationIdentifiers: Set<String> = [
        "public.image", "public.movie", "public.audio", "public.video", "public.audiovisual-content",
        "public.item", "public.content", "public.data", "public.composite-content", "public.directory", "public.folder",
        "com.apple.bundle", "com.apple.application-bundle", "public.camera-raw-image"
    ]
}
