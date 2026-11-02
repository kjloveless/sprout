import Foundation

indirect enum HTMLNode {
    case text(String)
    case element(String, [String: String], [HTMLNode])
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
    }
}

func page(title: String, content: HTMLNode) -> String {
    let document = HTMLNode.element("html", ["lang": "en"], [
        .element("head", [:], [
            .element("title", [:], [.text(title)])
        ]),
        .element("body", [:], [content])
    ])
    return "<!doctype html>" + render(document)
}
