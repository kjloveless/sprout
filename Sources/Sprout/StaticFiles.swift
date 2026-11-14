import Foundation

struct StaticAsset {
    let bytes: Data
    let contentType: String
}

enum StaticFileError: Error {
    case invalidDirectory
    case tooManyFiles
    case tooLarge
}

enum StaticFiles {
    static func load(from root: URL) throws -> [String: StaticAsset] {
        let files = FileManager.default
        var isDirectory: ObjCBool = false
        guard files.fileExists(atPath: root.path, isDirectory: &isDirectory) else {
            return [:]
        }
        let rootValues = try root.resourceValues(forKeys: [.isSymbolicLinkKey])
        guard isDirectory.boolValue, rootValues.isSymbolicLink != true else {
            throw StaticFileError.invalidDirectory
        }
        let rootComponents = root
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .pathComponents

        let keys: [URLResourceKey] = [
            .isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey
        ]
        var enumerationError: Error?
        guard let enumerator = files.enumerator(
            at: root, includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles],
            errorHandler: { _, error in enumerationError = error; return false }
        ) else {
            throw StaticFileError.invalidDirectory
        }
        var assets: [String: StaticAsset] = [:]
        var total = 0
        while let url = enumerator.nextObject() as? URL {
            let values = try url.resourceValues(forKeys: Set(keys))
            if values.isSymbolicLink == true {
                enumerator.skipDescendants()
                continue
            }
            guard values.isRegularFile == true else { continue }
            guard assets.count < 256 else { throw StaticFileError.tooManyFiles }
            guard let size = values.fileSize, size >= 0,
                size <= 1_048_576, size <= 4_194_304 - total else {
                    throw StaticFileError.tooLarge
            }
            let bytes = try Data(contentsOf: url)
            guard bytes.count <= 1_048_576, bytes.count <= 4_194_304 - total else {
                throw StaticFileError.tooLarge
            }
            total += bytes.count
            let fileComponents = url
                .resolvingSymlinksInPath()
                .standardizedFileURL
                .pathComponents

            guard fileComponents.starts(with: rootComponents),
                fileComponents.count > rootComponents.count else {
                    throw StaticFileError.invalidDirectory
            }

            let relative = fileComponents
                .dropFirst(rootComponents.count)
                .joined(separator: "/")

            assets[relative] = StaticAsset(
                bytes: bytes, 
                contentType: contentType(for: url.pathExtension)
            )
        }
        if let enumerationError { throw enumerationError }
        return assets
    }

    private static func contentType(for suffix: String) -> String {
        switch suffix.lowercased() {
        case "css": return "text/css; charset=utf-8"
        case "html": return "text/html; charset=utf-8"
        case "js": return "text/javascript; charset=utf-8"
        case "json": return "application/json"
        case "txt": return "text/plain; charset=utf-8"
        case "svg": return "image/svg+xml"
        case "png": return "image/png"
        case "jpg": return "image/jpeg"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "woff2": return "font/woff2"
        default: return "application/octet-stream"
        }
    }
}
