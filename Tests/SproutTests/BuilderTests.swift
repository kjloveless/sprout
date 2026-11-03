import XCTest
@testable import Sprout

final class BuildTests: XCTestCase {
    func testConditionalAndTextAreRenderedInOrder() {
        let showExtra = true
        let node = element("p") {
            "hello, "
            if showExtra {
                element("strong") { "swift" }
            }
        }
        XCTAssertEqual(render(node), "<p>hello, <strong>swift</strong></p>")
    }

    func testLoopBuildsChildren() {
        let names = ["ada", "kyle"]
        let list = element("ul") {
            for name in names {
                element("li") { name }
            }
        }
        XCTAssertEqual(
            render(list),
            "<ul><li>ada</li><li>kyle</li></ul>"
        )
    }
}
