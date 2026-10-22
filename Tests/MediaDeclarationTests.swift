import Foundation
import UniformTypeIdentifiers

/// The runner copies the target app's Info.plist into this executable's temporary
/// bundle. Bundle.main therefore exercises the same frozen mapping as the app.
/// This test only reads declarations; it never registers or changes a default.
@main
struct MediaDeclarationTests {
    static func main() {
        var report: [String] = [], failures = 0
        func check(_ condition: Bool, _ label: String) {
            report.append("\(condition ? "PASS" : "FAIL") \(label)")
            if !condition { failures += 1 }
        }
        let info = Bundle.main.infoDictionary ?? [:]
        let documents = info["CFBundleDocumentTypes"] as? [[String: Any]] ?? []
        let declared = Set(documents.flatMap { $0["LSItemContentTypes"] as? [String] ?? [] })
        let frozen = info["LumaViewFormatAssociations"] as? [String: String] ?? [:]
        let imports = info["UTImportedTypeDeclarations"] as? [[String: Any]] ?? []
        let importedIDs = imports.compactMap { $0["UTTypeIdentifier"] as? String }
        let importByID = Dictionary(imports.compactMap { entry -> (String, [String: Any])? in
            guard let identifier = entry["UTTypeIdentifier"] as? String else { return nil }
            return (identifier, entry)
        }, uniquingKeysWith: { first, _ in first })
        let catalogExtensions = Set(MediaFormats.associationFormats.flatMap(\.extensions))
        let runtimeTypes = MediaFormats.associationFormats.flatMap(\.associationTypes)
        let runtimeIDs = Set(runtimeTypes.map(\.identifier))

        check(!frozen.isEmpty, "The app contains a frozen extension-to-UTI map")
        check(Set(frozen.keys) == catalogExtensions, "Frozen map covers exactly the selectable catalog extensions")
        for (suffix, identifier) in ["jpg": "public.jpeg", "png": "public.png", "mp4": "public.mpeg-4",
                                      "mp3": "public.mp3", "pdf": "com.adobe.pdf"].sorted(by: { $0.key < $1.key }) {
            check(frozen[suffix] == identifier && declared.contains(identifier),
                  "Canonical .\(suffix) uses and declares \(identifier)")
        }
        check(!declared.isEmpty && declared.isDisjoint(with: MediaFormats.forbiddenAssociationIdentifiers),
              "Document declarations contain concrete formats without abstract category handlers")
        check(runtimeTypes.allSatisfy { !$0.isDynamic }, "Runtime associations contain no dynamic guessed types")
        check(runtimeIDs.isSubset(of: declared), "Every runtime selection type is declared by this exact app bundle")
        check(Set(frozen.values) == declared, "Frozen mapping and document declarations stay in exact agreement")
        let honorsFrozenMap = MediaFormats.associationFormats.allSatisfy { format in
            format.extensions.allSatisfy {
                frozen[$0] == MediaFormats.associationType(for: $0, category: format.category).identifier
            }
        }
        check(honorsFrozenMap, "Runtime resolution honors every shipped mapping instead of reselecting system aliases")
        check(documents.count == MediaCategory.allCases.count
              && documents.allSatisfy { ($0["CFBundleTypeRole"] as? String) == "Viewer" && ($0["LSHandlerRank"] as? String) == "Alternate" },
              "All four document categories remain alternate viewers and do not claim automatic defaults")
        let custom = Set(frozen.values.filter { $0.hasPrefix("io.local.lumaview.format.") })
        check(Set(importedIDs) == custom && importedIDs.count == custom.count,
              "Every custom mapping has one matching imported UTI declaration")
        let customTagsMatch = MediaFormats.associationFormats.allSatisfy { format in
            format.extensions.allSatisfy { suffix in
                guard let identifier = frozen[suffix], custom.contains(identifier) else { return true }
                guard let entry = importByID[identifier],
                      let tags = entry["UTTypeTagSpecification"] as? [String: Any],
                      let extensions = tags["public.filename-extension"] as? [String],
                      let parents = entry["UTTypeConformsTo"] as? [String] else { return false }
                let expectedParent = format.category == .audio ? UTType.audio.identifier
                    : format.category == .video ? UTType.movie.identifier : UTType.image.identifier
                return extensions.contains(suffix) && parents.contains(expectedParent)
            }
        }
        check(customTagsMatch, "Imported declarations retain each extension and its expected media category")
        let summary = "\(report.count - failures) passed, \(failures) failed"
        report.append(summary)
        let text = report.joined(separator: "\n") + "\n"
        print(text)
        if CommandLine.arguments.count > 1 {
            try? text.write(to: URL(fileURLWithPath: CommandLine.arguments[1]), atomically: true, encoding: .utf8)
        }
        exit(failures == 0 ? 0 : 1)
    }
}
