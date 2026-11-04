import Foundation

struct MissingAsset: Error {
    let name: String
}

struct Assets {
    let runtime: String
    let counter: String
    let staticFiles: [String: StaticAsset]

    init(runtime: String, counter: String,
        staticFiles: [String: StaticAsset] = [:]) {
        self.runtime = runtime
        self.counter = counter
        self.staticFiles = staticFiles
    }

    static func load() throws -> Assets {
        func loadJS(_ name: String) throws -> String {
            guard let url = Bundle.module.url(
                forResource: name, 
                withExtension: "js", 
                subdirectory: "Public"
            ) else {
                throw MissingAsset(name: name)
            }
            
            return try String(contentsOf: url, encoding: .utf8)
        }

        let staticRoot = URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath,
            isDirectory: true
        ).appendingPathComponent("static", isDirectory: true)

        return try Assets(
            runtime: loadJS("runtime"), counter: loadJS("counter"),
            staticFiles: StaticFiles.load(from: staticRoot)
        )
    }
}
