import XCTest
import NIOHTTP1
@testable import Sprout

final class SproutTests: XCTestCase {
    func testTextIsEscaped() {
        XCTAssertEqual(
            render(.text("<script>&")),
            "&lt;script&gt;&amp;"
        )
    }

    func testPlainPageDoesNotLoadRuntime() {
        let content = HTMLNode.element("h1", [:], [.text("about")])
        let html = page(title: "about", content: content)
        XCTAssertFalse(html.contains("/assets/runtime.js"))
    }

    func testIslandPageLoadsRuntime() {
        let content = HTMLNode.island(
            name: "counter",
            props: "{}",
            children: [.text("counter")]
        )
        let html = page(title: "home", content: content)
        XCTAssertTrue(html.contains("/assets/runtime.js"))
    }

    func testDynamicNameIsRenderedAsText() {
        let router = Router(assets: Assets(runtime: "", counter: ""))
        let request = HTTPRequestHead(
            version: .http1_1,
            method: .GET,
            uri: "/hello/%3Cscript%3E"
        )
        let reply = router.handle(request)
        XCTAssertEqual(reply.status, .ok)
        XCTAssertTrue(reply.body.contains("hello, &lt;script&gt;!"))
        XCTAssertFalse(reply.body.contains("<script>"))
    }

    func testUnknownPathAndUnsupportedMethod() {
        let router = Router(assets: Assets(runtime: "", counter: ""))
        let missing = HTTPRequestHead(
            version: .http1_1, method: .GET, uri: "/missing"
        )
        let post = HTTPRequestHead(
            version: .http1_1, method: .POST, uri: "/"
        )
        XCTAssertEqual(router.handle(missing).status, .notFound)
        XCTAssertEqual(router.handle(post).status, .methodNotAllowed)
    }
}
