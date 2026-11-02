import Foundation

struct MissingAsset: Error {
    let name: String
}

struct Assets {
    let runtime: String
    let counter: String

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

        return Assets(
            runtime: try loadJS("runtime"), 
            counter: try loadJS("counter")
        )
    }
}
