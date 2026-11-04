import NIOHTTP1

typealias Layout = (HTMLNode) -> HTMLNode

struct PageContext {
    let request: WebRequest
    let parameters: [String: String]
    let assets: Assets
    let state: RequestState
    let layouts: [Layout]

    func html(title: String, content: HTMLNode) -> Reply {
        let wrapped = layouts.reversed().reduce(content) { node, layout in
            layout(node)
        }

        return .html(page(title: title, content: wrapped))
    }
}

struct Route {
    let components: [String]
    let method: HTTPMethod
    let layouts: [Layout]
    let handler: (PageContext) -> Reply

    init(_ pattern: String, method: HTTPMethod = .GET, layouts: [Layout] = [],
        handler: @escaping (PageContext) -> Reply) {
        components = pattern.split(separator: "/").map(String.init)
        self.method = method
        self.layouts = layouts
        self.handler = handler
    }

    var shape: [String] {
        components.map {
            if $0.hasPrefix("*") { return "*" }
            if $0.hasPrefix(":") { return $0.hasSuffix("?") ? ":?" : ":" }
            return $0
        }
    }

    func match(_ path: [String]) -> [String: String]? {
        func visit(_ i: Int, _ offset: Int,
            _ parameters: [String: String]) -> [String: String]? {
            if i == components.count { return offset == path.count ? parameters : nil }
            let component = components[i]
            if component.hasPrefix("*") {
                let name = String(component.dropFirst())
                guard i == components.count - 1, !name.isEmpty,
                    parameters[name] == nil else { return nil }
                var next = parameters
                next[name] = path[offset...].joined(separator: "/")
                return next
            }
            if component.hasPrefix(":") {
                let optional = component.hasSuffix("?")
                let end = optional ? component.index(before: component.endIndex)
                                    : component.endIndex
                let start = component.index(after: component.startIndex)
                let name = String(component[start..<end])
                guard !name.isEmpty, parameters[name] == nil else { return nil }
                if offset < path.count {
                    var next = parameters
                    next[name] = path[offset]
                    if let found = visit(i + 1, offset + 1, next) { return found }
                }

                return optional ? visit(i + 1, offset, parameters) : nil
            }
            guard offset < path.count, component == path[offset] else { return nil }
            return visit(i + 1, offset + 1, parameters)
        }

        return visit(0, 0, [:])
    }
}

typealias Middleware = (PageContext, () -> Reply) -> Reply

struct ScopedMiddleware {
    let prefix: [String]
    let run: Middleware
}
