struct GuideLayout {
    static func render(_ child: HTMLNode) -> HTMLNode {
        element("section", attributes: ["class": "guide"]) {
            element("p") { "the sprout guide" }
            child
        }
    }
}
