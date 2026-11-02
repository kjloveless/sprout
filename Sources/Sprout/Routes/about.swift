struct AboutRoute {
    static func render(_ context: PageContext) -> Reply {
        let content = HTMLNode.element("main", [:], [
            .element("h1", [:], [.text("about sprout")]),
            .element("a", ["href": "/"], [.text("home")])
        ])

        return .html(page(title: "about", content: content))
    }
}
