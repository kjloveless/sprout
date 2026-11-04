struct GuideIndexRoute {
    static func render(_ context: PageContext) -> Reply {
        let content = element("main") {
            element("h1") { "nesting layouts" }
            element("p") { "this page inherits the root and guide layouts." }
        }
        return context.html(title: "guide", content: content)
    }
}
