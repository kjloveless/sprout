import XCTest
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
