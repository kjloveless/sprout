import XCTest
import NIOHTTP1
@testable import Sprout

final class RouteMatchingTests: XCTestCase {
    func testParameterizedPattern() {
        let route = Route("/hello/:name", handler: { _ in .text("ok") })
        XCTAssertEqual(route.match(["hello", "ada"]), ["name": "ada"])
        XCTAssertNil(route.match(["hello"]))
        XCTAssertNil(route.match(["goobye", "ada"]))
    }

    func testDecodePathAndQuery() {
        XCTAssertEqual(
            Router.decodePath("/hello/ada%20lovelace?from=book"),
            ["hello", "ada lovelace"]
        )
        XCTAssertEqual(Router.decodePath("/"), [])
    }

    func testRejectEncodedSeparatorsAndInvalidPercentEncoding() {
        XCTAssertNil(Router.decodePath("/hello/a%2Fb"))
        XCTAssertNil(Router.decodePath("/hello/a%5Cb"))
        XCTAssertNil(Router.decodePath("/hello/%ZZ"))
        XCTAssertNil(Router.decodePath("/hello/.."))
    }
}

extension RouteMatchingTests {
    func testOptionalSegmentCanBeSkippedOrConsumed() {
        let route = Route("/docs/:version?/intro", handler: { _ in .text("ok") })
        XCTAssertEqual(route.match(["docs", "intro"]), [:])
        XCTAssertEqual(route.match(["docs", "v1", "intro"]), ["version": "v1"])
        XCTAssertNil(route.match(["docs", "v1", "other"]))
    }

    func testCatchallCapturesTheRest() {
        let route = Route("/old/*path", handler: { _ in .text("ok") })
        XCTAssertEqual(route.match(["old"]), ["path": ""])
        XCTAssertEqual(route.match(["old", "a", "b"]), ["path": "a/b"])
        XCTAssertNil(route.match(["other", "a"]))
    }

    func testGeneratedOptionalAndCatchallRoutes() {
        let router = Router(assets: Assets(runtime: "", counter: ""))
        func get(_ path: String) -> Reply {
            router.handle(HTTPRequestHead(version: .http1_1, method: .GET, uri: path))
        }
        XCTAssertTrue(get("/docs").body.contains("documentation: latest"))
        XCTAssertTrue(get("/docs/v2").body.contains("documentation: v2"))
        XCTAssertTrue(get("/docs").body.contains("learning routes"))
        XCTAssertTrue(get("/old/a/b").body.contains("old path: a/b"))
    }
}
