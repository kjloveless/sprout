struct HelloNameRoute {
    static func render(_ context: PageContext) -> Reply {
        guard let name = context.parameters["name"] else {
            return .text("missing route parameter\n", status: .internalServerError)
        }
        let content = HTMLNode.element("h1", [:], [
            .text("hello, \(name)!")
        ])

        return .html(page(title: "greetings", content: content))
    }
}
