import Foundation
import NIOHTTP1
import XCTest
@testable import Sprout

final class StaticFilesTests: XCTestCase {
    func testBinaryFilesAndHiddenFilesAndLinks() throws {
        let files = FileManager.default
        let temp = files.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try files.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? files.removeItem(at: temp) }
        let binary = Data([0, 1, 255, 42])
        try binary.write(to: temp.appendingPathComponent("image.png"))
        try Data("secret".utf8).write(to: temp.appendingPathComponent(".hidden"))
        try files.createSymbolicLink(
            at: temp.appendingPathComponent("link.txt"), 
            withDestinationURL: temp.appendingPathComponent("image.png")
        )
        let assets = try StaticFiles.load(from: temp)

        XCTAssertEqual(assets["image.png"]?.bytes, binary)
        XCTAssertEqual(assets["image.png"]?.contentType, "image/png")
        XCTAssertNil(assets[".hidden"])
        XCTAssertNil(assets["link.txt"])
        let router = Router(assets: Assets(runtime: "", counter: "", staticFiles: assets))
        let get = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/image.png")
        let post = HTTPRequestHead(version: .http1_1, method: .POST, uri: "/image.png")
        XCTAssertEqual(router.handle(get).payload, binary)
        XCTAssertEqual(router.handle(post).status, .methodNotAllowed)
    }

    func testStaticFileSizeLimit() throws {
        let files = FileManager.default
        let temp = files.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try files.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? files.removeItem(at: temp) }
        try Data(repeating: 1, count: 1_048_577)
            .write(to: temp.appendingPathComponent("large.bin"))
        XCTAssertThrowsError(try StaticFiles.load(from: temp))
    }

    func testQueryAndJSONRoute() throws {
        let router = Router(assets: Assets(runtime: "", counter: ""))
        let head = HTTPRequestHead(
            version: .http1_1, method: .GET, uri: "/api/hello?name=Ada+Lovelace"
        )
        let response = router.handle(head)
        XCTAssertEqual(response.status, .ok)
        XCTAssertTrue(response.contentType.hasPrefix("application/json"))
        let decoded = try JSONSerialization.jsonObject(with: response.payload)
        XCTAssertEqual((decoded as? [String: String])?["greeting"], "hello, Ada Lovelace!!")
    }
}
