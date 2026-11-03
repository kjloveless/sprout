struct AboutRoute {
    static func render(_ context: PageContext) -> Reply {
        let content = element("main") {
            element("h1") { "about sprout" }
            element("p") { "built with swiftnio." }
            element("a", attributes: ["href": "/"]) { "home" }
        }

        return .html(page(title: "about", content: content))
    }
}
