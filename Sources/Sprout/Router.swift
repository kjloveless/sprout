import Foundation
import NIOHTTP1

struct Router {
    let assets: Assets
    private let routes: [Route]

    init(assets: Assets) {
        self.assets = assets
        self.routes = generatedRoutes()
    }

    func handle(_ request: HTTPRequestHead) -> Reply {
        guard request.method == .GET else {
            return .text("method not allowed\n", status: .methodNotAllowed)
        }
        guard let path = Self.decodePath(request.uri) else {
            return .text("bad request\n", status: .badRequest)
        }
        if path == ["assets", "runtime.js"] {
            return .javascript(assets.runtime)
        }
        if path == ["assets", "counter.js"] {
            return .javascript(assets.counter)
        }

        for route in routes {
            if let parameters = route.match(path) {
                let context = PageContext(parameters: parameters, assets: assets)
                return route.handler(context)
            }
        }

        return .text("not found\n", status: .notFound)
    }

    static func decodePath(_ target: String) -> [String]? {
        let encoded = target.split(
            separator: "?", maxSplits: 1, omittingEmptySubsequences: false
        ).first.map(String.init) ?? ""
        guard encoded.hasPrefix("/") else { return nil }

        var components: [String] = []
        for raw in encoded.split(separator: "/") {
            guard let part = String(raw).removingPercentEncoding,
                !part.isEmpty, !part.contains("/"), !part.contains("\\"),
                part != ".", part != ".." else { return nil }
            components.append(part)
        }

        return components
    }
}
