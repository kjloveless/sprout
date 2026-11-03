@resultBuilder
enum HTMLBuilder {
    static func buildExpression(_ node: HTMLNode) -> [HTMLNode] {
        [node]
    }

    static func buildExpression(_ text: String) -> [HTMLNode] {
        [.text(text)]
    }

    static func buildBlock(_ components: [HTMLNode]...) -> [HTMLNode] {
        components.flatMap { $0 }
    }

    static func buildOptional(_ component: [HTMLNode]?) -> [HTMLNode] {
        component ?? []
    }

    static func buildEither(first component: [HTMLNode]) -> [HTMLNode] {
        component
    }

    static func buildEither(second component: [HTMLNode]) -> [HTMLNode] {
        component
    }

    static func buildArray(_ components: [[HTMLNode]]) -> [HTMLNode] {
        components.flatMap { $0 }
    }
}

func element(
    _ name: String, 
    attributes: [String: String] = [:], 
    @HTMLBuilder content: () -> [HTMLNode]
) -> HTMLNode {
    .element(name, attributes, content())
}
