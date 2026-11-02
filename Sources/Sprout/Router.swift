import Foundation
import NIOHTTP1

struct Router {
    let assets: Assets

    func handle(_ request: HTTPRequestHead) -> Reply {
        guard request.method == .GET else {
            return .text("method not allowed\n", status: .methodNotAllowed)
        }

        let path = request.uri.split(
            separator: "?", maxSplits: 1
        ).first.map(String.init) ?? "/"

        if path.hasPrefix("/hello/") {
            let rawName = String(path.dropFirst("/hello/".count))
            guard !rawName.isEmpty,
                let name = rawName.removingPercentEncoding,
                !name.contains("/") else {
                    return .text("bad request\n", status: .badRequest)
                }

                let content = HTMLNode.element("h1", [:], [
                    .text("hello, \(name)!")
                ])
                return .html(page(title: "greetings", content: content))
        }

        switch path {
        case "/":
            guard let counter = try? makeCounter(initial: 3) else {
                return .text("could not render\n", status: .internalServerError)
            }
            let content = HTMLNode.element("main", [:], [
                .element("h1", [:], [.text("our first island")]),
                .element("p", [:], [.text("the rest of this page is static.")]),
                counter,
                counter,
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

        case "/assets/runtime.js":
            return .javascript(assets.runtime)

        case "/assets/counter.js":
            return .javascript(assets.counter)

        default:
            return .text("not found\n", status: .notFound)
        }
    }
}
