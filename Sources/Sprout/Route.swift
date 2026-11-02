import Foundation

struct PageContext {
    let parameters: [String: String]
    let assets: Assets
}

struct Route {
    let components: [String]
    let handler: (PageContext) -> Reply

    init(_ pattern: String, handler: @escaping (PageContext) -> Reply) {
        self.components = pattern.split(separator: "/").map(String.init)
        self.handler = handler
    }

    func match(_ path: [String]) -> [String: String]? {
        guard components.count == path.count else { return nil }
        var parameters: [String: String] = [:]
        for (expected, actual) in zip(components, path) {
            if expected.hasPrefix(":") {
                let name = String(expected.dropFirst())
                guard !name.isEmpty, parameters[name] == nil else { return nil }
                parameters[name] = actual
            } else if expected != actual {
                return nil
            }
        }

        return parameters
    }
}
