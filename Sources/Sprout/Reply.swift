import Foundation
import NIOHTTP1

struct Reply {
    let status: HTTPResponseStatus
    let contentType: String
    let body: String
    var headers: HTTPHeaders = HTTPHeaders()
    var binaryBody: Data?

    var payload: Data { binaryBody ?? Data(body.utf8) }

    func withHeader(_ name: String, _ value: String) -> Reply {
        var copy = self
        copy.headers.replaceOrAdd(name: name, value: value)
        return copy
    }

    static func text(
        _ body: String,
        status: HTTPResponseStatus = .ok
    ) -> Reply {
        Reply(
            status: status,
            contentType: "text/plain; charset=utf-8",
            body: body
        )
    }

    static func html(_ body: String) -> Reply {
        Reply(
            status: .ok,
            contentType: "text/html; charset=utf-8",
            body: body
        )
    }

    static func javascript(_ body: String) -> Reply {
        Reply(
            status: .ok,
            contentType: "text/javascript; charset=utf-8",
            body: body
        )
    }

    static func bytes(_ bytes: Data, contentType: String) -> Reply {
        var reply = Reply(
            status: .ok, 
            contentType: contentType,
            body: ""
        )
        reply.binaryBody = bytes
        return reply
    }

    static func json<T: Encodable>(_ value: T) throws -> Reply {
        let data = try JSONEncoder().encode(value)
        return Reply(
            status: .ok,
            contentType: "application/json; charset=utf-8",
            body: String(decoding: data, as: UTF8.self)
        )
    }
}
