struct GroupLearnLayout {
    static func render(_ child: HTMLNode) -> HTMLNode {
        element("section", attributes: ["class": "learning"]) {
            element("p") { "learning routes" }
            child
        }
    }
}
