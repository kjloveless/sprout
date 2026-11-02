import NIOCore
import NIOHTTP1

final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private let router: Router
    private var requestHead: HTTPRequestHead?

    init(router: Router) {
        self.router = router
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        switch unwrapInboundIn(data) {
        case .head(let head):
            requestHead = head

        case .body:
            break

        case .end:
            guard let request = requestHead else {
                context.close(promise: nil)
                return
            }
            requestHead = nil
            let reply = router.handle(request)
            send(reply, for: request, on: context)
        }
    }

    private func send(
        _ reply: Reply,
        for request: HTTPRequestHead,
        on context: ChannelHandlerContext
    ) {
        let bytes = Array(reply.body.utf8)
        var head = HTTPResponseHead(
            version: request.version,
            status: reply.status
        )
        head.headers.add(name: "content-type", value: reply.contentType)
        if request.method != .HEAD {
            head.headers.add(name: "content-length", value: String(bytes.count))
        }
        head.headers.add(name: "connection", value: "close")
        if reply.status == .methodNotAllowed {
            head.headers.add(name: "allow", value: "GET")
        }

        context.write(wrapOutboundOut(.head(head)), promise: nil)
        if request.method != .HEAD {
            var buffer = context.channel.allocator.buffer(capacity: bytes.count)
            buffer.writeBytes(bytes)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        }

        let done = context.eventLoop.makePromise(of: Void.self)
        let channel = context.channel
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: done)
        done.futureResult.whenComplete { _ in
            channel.close(promise: nil)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        context.close(promise: nil)
    }
}
