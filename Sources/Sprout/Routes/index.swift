struct IndexRoute {
    static func render(_ context: PageContext) -> Reply {
        guard let counter = try? makeCounter(initial: 3) else {
            return .text("could not render\n", status: .internalServerError)
        }
        let content = HTMLNode.element("main", [:], [
            .element("h1", [:], [.text("islands!")]),
            .element("p", [:], [.text("the rest of this page is static.")]),
            counter,
            counter,
            .element("a", ["href": "/about"], [.text("about")])
        ])

        return .html(page(title: "home", content: content))
    }
}
