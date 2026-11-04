struct OldCatchallPathRoute {
    static func render(_ context: PageContext) -> Reply {
        let path = context.parameters["path"] ?? ""
        let content = element("main") {
            element("h1") { "old path: \(path)" }
        }
        return context.html(title: "old paths", content: content)
    }
}
