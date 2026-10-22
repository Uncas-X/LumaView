import Foundation
import UniformTypeIdentifiers

@main
enum GenerateMediaDeclarations {
    static func main() {
        do { try generate() }
        catch {
            FileHandle.standardError.write(Data((error.localizedDescription + "\n").utf8))
            exit(1)
        }
    }

    private static func generate() throws {
        guard CommandLine.arguments.count == 3 else {
            throw NSError(domain: "LumaView.MediaDeclarations", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Expected base and output Info.plist paths"])
        }
        let base = URL(fileURLWithPath: CommandLine.arguments[1])
        let output = URL(fileURLWithPath: CommandLine.arguments[2])
        var plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: base), format: nil) as! [String: Any]
        let canonical: [(String, MediaCategory, String)] = [
            ("jpg", .image, "public.jpeg"), ("png", .image, "public.png"),
            ("mp4", .video, "public.mpeg-4"), ("mp3", .audio, "public.mp3"), ("pdf", .vector, "com.adobe.pdf")
        ]
        for (suffix, category, expected) in canonical {
            guard MediaFormats.associationType(for: suffix, category: category).identifier == expected else {
                throw NSError(domain: "LumaView.MediaDeclarations", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Cannot read canonical macOS UTI for .\(suffix). Run this generator in a normal desktop session with LaunchServices access; no output was written."])
            }
        }
        var imported: [[String: Any]] = []
        var documents: [[String: Any]] = []
        var associations: [String: String] = [:]
        var seen = Set<String>()
        for category in MediaCategory.allCases {
            var identifiers = Set<String>()
            for format in MediaFormats.associationFormats where format.category == category {
                for suffix in format.extensions {
                    let type = MediaFormats.associationType(for: suffix, category: category)
                    identifiers.insert(type.identifier)
                    associations[suffix.lowercased()] = type.identifier
                    if type.identifier.hasPrefix("io.local.lumaview.format."), seen.insert(type.identifier).inserted {
                        let parent = category == .audio ? UTType.audio : category == .video ? .movie : .image
                        imported.append([
                            "UTTypeIdentifier": type.identifier,
                            "UTTypeDescription": format.title,
                            "UTTypeConformsTo": [parent.identifier],
                            "UTTypeTagSpecification": ["public.filename-extension": [suffix]]
                        ])
                    }
                }
            }
            documents.append([
                "CFBundleTypeName": category.title, "CFBundleTypeRole": "Viewer",
                "LSHandlerRank": "Alternate", "LSItemContentTypes": identifiers.sorted()
            ])
        }
        plist["CFBundleDocumentTypes"] = documents
        plist["UTImportedTypeDeclarations"] = imported
        plist["LumaViewFormatAssociations"] = associations
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: output, options: .atomic)
    }
}
