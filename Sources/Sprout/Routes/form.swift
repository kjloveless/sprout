struct FormRoute {
    static func render(_ context: PageContext) -> Reply {
        let content = element("main") {
            element("h1") { "say hello" }
            element("form", attributes: ["method": "post", "action": "/form"]) {
                element("label") {
                    "name: "
                    element("textarea", attributes: ["name": "name"]) { "" }
                }
                element("button", attributes: ["type": "submit"]) { "send" }
            }
        }
        return context.html(title: "a form", content: content)
    }
}
