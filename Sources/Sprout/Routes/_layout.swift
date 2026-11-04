struct RootLayout {
    static func render(_ child: HTMLNode) -> HTMLNode {
        element("div") {
            element("header") {
                element("a", attributes: ["href": "/"]) { "sprout" }
            }
            child
        }
    }
}
