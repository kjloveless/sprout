import Foundation
import NIOHTTP1

struct Router {
    let assets: Assets
    private let routes: [Route]
    private let middleware: [ScopedMiddleware]

    init(assets: Assets, routes: [Route]? = nil,
        middleware: [ScopedMiddleware] = []) {
        self.assets = assets
        self.routes = routes ?? generatedRoutes()
        self.middleware = middleware
    }

    func handle(_ head: HTTPRequestHead) -> Reply {
        handle(WebRequest(head: head, body: Data()))
    }

    func handle(_ request: WebRequest) -> Reply {
        guard let path = Self.decodePath(request.target) else {
            return .text("bad request\n", status: .badRequest)
        }
        let endpoint: (PageContext) -> Reply
        var parameters: [String: String] = [:]
        var layouts: [Layout] = []
        if path.count == 2, path[0] == "assets",
            ["runtime.js", "counter.js"].contains(path[1]) {
            if request.method == .GET || request.method == .HEAD {
                let content = path[1] == "runtime.js" ? assets.runtime : assets.counter
                endpoint = { _ in .javascript(content) }
            } else {
                endpoint = { _ in Self.methodNotAllowed(["GET", "HEAD"]) }
            }
        } else if let asset = assets.staticFiles[path.joined(separator: "/")] {
            if request.method == .GET || request.method == .HEAD {
                endpoint = { _ in .bytes(asset.bytes, contentType: asset.contentType) }
            } else {
                endpoint = { _ in Self.methodNotAllowed(["GET", "HEAD"]) }
            }
        } else {
            let matches = routes.compactMap {
                route -> (Route, [String: String])? in
                    guard let parameters = route.match(path) else { return nil }
                    return (route, parameters)
            }
            if let first = matches.first {
                let group = matches.filter { $0.0.shape == first.0.shape }
                let selected = group.first { $0.0.method == request.method }
                    ?? (request.method == .HEAD ? group.first { $0.0.method == .GET } : nil)
                if let selected {
                    parameters = selected.1
                    layouts = selected.0.layouts
                    endpoint = selected.0.handler
                } else {
                    var allowed = Set(group.map { $0.0.method.rawValue })
                    if allowed.contains("GET") { allowed.insert("HEAD") }
                    let values = allowed.sorted()
                    endpoint = { _ in Self.methodNotAllowed(values) }
                }
            } else {
                endpoint = { _ in .text("not found\n", status: .notFound) }
            }
        }
        let context = PageContext(
            request: request, parameters: parameters,
            assets: assets, state: RequestState(), layouts: layouts
        )
        let chain = middleware.filter { path.starts(with: $0.prefix) }
        func run(_ i: Int) -> Reply {
            if i == chain.count { return endpoint(context) }
            return chain[i].run(context) { run(i + 1) }
        }

        return run(0)
    }

    private static func methodNotAllowed(_ methods: [String]) -> Reply {
        .text("method not allowed\n", status: .methodNotAllowed)
            .withHeader("allow", methods.joined(separator: ", "))
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
