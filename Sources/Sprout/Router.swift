import Foundation
import NIOHTTP1

struct Router {
    func handle(_ request: HTTPRequestHead) -> Reply {
        guard request.method == .GET else {
            return .text("method not allowed\n", status: .methodNotAllowed)
        }

        let path = request.uri.split(
            separator: "?", maxSplits: 1
        ).first.map(String.init) ?? "/"

        switch path {
        case "/":
            let content = HTMLNode.element("main", [:], [
                .element("h1", [:], [.text("hello, swiftnio!")]),
                .element("p", [:], [.text("we made a page in swift.")]),
                .element("a", ["href": "/about"], [.text("about")])
            ])
            return .html(page(title: "home", content: content))

        case "/about":
            let content = HTMLNode.element("main", [:], [
                .element("h1", [:], [.text("about sprout")]),
                .element("a", ["href": "/"], [.text("home")])
            ])
            return .html(page(title: "about", content: content))

        case "/health":
            return .text("ok")

        default:
            return .text("not found\n", status: .notFound)
        }
    }
}
