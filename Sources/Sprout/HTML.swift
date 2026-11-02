import Foundation

indirect enum HTMLNode {
    case text(String)
    case element(String, [String: String], [HTMLNode])
    case island(name: String, props: String, children: [HTMLNode])

    var hasIsland: Bool {
        switch self {
        case .text:
            return false

        case .element(_, _, let children):
            return children.contains { $0.hasIsland }

        case .island:
            return true
        }
    }
}

func escapeHTML(_ value: String) -> String {
    value
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&#39;")
}

func render(_ node: HTMLNode) -> String {
    switch node {
    case .text(let value):
        return escapeHTML(value)

    case .element(let name, let attributes, let children):
        let attrs = attributes.keys.sorted().map { key in
            " \(key)=\"\(escapeHTML(attributes[key]!))\""
        }.joined()
        let content = children.map(render).joined()
        return "<\(name)\(attrs)>\(content)</\(name)>"

    case .island(let name, let props, let children):
        return render(.element("div", [
            "data-island": name,
            "data-props": props
        ], children))
    }
}

func page(title: String, content: HTMLNode) -> String {
    var bodyChildren: [HTMLNode] = [content]

    if content.hasIsland {
        bodyChildren.append(.element("script", [
            "type": "module",
            "src": "/assets/runtime.js"
        ], []))
    }

    let document = HTMLNode.element("html", ["lang": "en"], [
        .element("head", [:], [
            .element("title", [:], [.text(title)])
        ]),
        .element("body", [:], bodyChildren)
    ])
    return "<!doctype html>" + render(document)
}
