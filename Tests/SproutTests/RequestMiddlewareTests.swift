import Foundation
import NIOHTTP1
import XCTest
@testable import Sprout

final class RequestMiddlewareTests: XCTestCase {
    private let assets = Assets(runtime: "", counter: "")

    private func request(_ method: HTTPMethod, _ path: String,
                        body: String = "", type: String? = nil) -> WebRequest {
        var head = HTTPRequestHead(version: .http1_1, method: method, uri: path) 
        if let type { head.headers.add(name: "content-type", value: type) }
        return WebRequest(head: head, body: Data(body.utf8))
    }

    func testFormDecodingKeepsDuplicatesAndEscapes() throws {
        let req = request(.POST, "/form", body: "name=ada+lovelace&name=%3Ctag%3E",
                            type: "application/x-www-form-urlencoded; charset=utf-8")
        let fields = try req.form()
        XCTAssertEqual(fields.map { $0.0 }, ["name", "name"])
        XCTAssertEqual(fields.map { $0.1 }, ["ada lovelace", "<tag>"])
    }

    func testFormRejectsInvalidEscapeAndContentType() {
        let bad = request(.POST, "/form", body: "name=%ZZ",
                            type: "application/x-www-form-urlencoded")
        let wrong = request(.POST, "/form", body: "name=ada", type: "text/plain")
        XCTAssertThrowsError(try bad.form())
        XCTAssertThrowsError(try wrong.form())
    }

    func testMethodsStayWithinMostSpecificPath() {
        let router = Router(assets: assets, routes: [
            Route("/post/new", handler: { _ in .text("literal") }),
            Route("/post/:name", method: .POST, handler: { _ in .text("parameter") })
        ])
        XCTAssertEqual(router.handle(request(.GET, "/post/new")).body, "literal")
        XCTAssertEqual(router.handle(request(.POST, "/post/ada")).body, "parameter")
        let wrong = router.handle(request(.POST, "/post/new"))
        XCTAssertEqual(wrong.status, .methodNotAllowed)
        XCTAssertEqual(wrong.headers.first(name: "allow"), "GET, HEAD")
        XCTAssertEqual(router.handle(request(.POST, "/missing")).status, .notFound)
        XCTAssertEqual(router.handle(request(.HEAD, "/post/new")).body, "literal")
    }

    func testMiddlewareOnionScopeAndState() {
        var trace: [String] = []
        let outer = ScopedMiddleware(prefix: []) { context, next in 
            trace.append("outer-in")
            context.state["user"] = "Ada"
            let reply = next()
            trace.append("outer-out")
            return reply.withHeader("x-outer", "yes")
        }
        let admin = ScopedMiddleware(prefix: ["admin"]) { _, next in
            trace.append("admin-in")
            let reply = next()
            trace.append("admin-out")
            return reply
        }
        let router = Router(assets: assets, routes: [
            Route("/admin", handler: { context in
                trace.append("handler")
                return .text(context.state["user"] ?? "missing")
            }),
            Route("/administrator", handler: { _ in .text("other") })
        ], middleware: [outer, admin])
        let reply = router.handle(request(.GET, "/admin"))
        XCTAssertEqual(reply.body, "Ada")
        XCTAssertEqual(reply.headers.first(name: "x-outer"), "yes")
        XCTAssertEqual(trace, ["outer-in", "admin-in", "handler",
                                "admin-out", "outer-out"])
        trace = []
        XCTAssertEqual(router.handle(request(.GET, "/administrator")).body, "other")
        XCTAssertEqual(trace, ["outer-in", "outer-out"])
    }

    func testMiddlewareWrapsMissingRoutesAndCanShortCircuit() {
        let global = ScopedMiddleware(prefix: []) { _, next in
            next().withHeader("x-global", "yes")
        }
        let block = ScopedMiddleware(prefix: ["admin"]) { _, _ in
            .text("blocked", status: .forbidden)
        }
        let router = Router(assets: assets, routes: [
            Route("/admin", handler: { _ in .text("unreachable") })
        ], middleware: [global, block])
        let missing = request(.GET, "/missing")
        XCTAssertEqual(router.handle(missing).status, .notFound)
        XCTAssertEqual(router.handle(missing).headers.first(name: "x-global"), "yes")
        XCTAssertEqual(router.handle(request(.GET, "/admin")).status, .forbidden)
    }

    func testLayoutInheritanceOrder() {
        let outer: Layout = { child in .element("div", ["id": "outer"], [child]) }
        let inner: Layout = { child in .element("section", ["id": "inner"], [child]) }
        let route = Route("/guide", layouts: [outer, inner]) { context in 
            context.html(title: "guide", content: .text("page"))
        }
        let router = Router(assets: assets, routes: [route])
        let result = router.handle(request(.GET, "/guide"))
        XCTAssertTrue(result.body.contains(
            #"<div id="outer"><section id="inner">page</section></div>"#
        ))
    }
}
