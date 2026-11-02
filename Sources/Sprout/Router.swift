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
            return .text("this is the home page.\n")

        case "/about":
            return .text("this is the about page.\n")

        case "/health":
            return .text("ok")

        default:
            return .text("not found\n", status: .notFound)
        }
    }
}
