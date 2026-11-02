import NIOHTTP1

struct Reply {
    let status: HTTPResponseStatus
    let contentType: String
    let body: String

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
}
