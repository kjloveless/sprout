import Foundation
import NIOCore
import NIOHTTP1

final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private let router: Router
    private let bodyLimit = 1_048_576
    private var requestHead: HTTPRequestHead?
    private var body: ByteBuffer?
    private var closing = false

    init(router: Router) {
        self.router = router
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        guard !closing else { return }
        switch unwrapInboundIn(data) {
        case .head(let head):
            guard requestHead == nil else {
                closing = true
                context.close(promise: nil)
                return
            }
            requestHead = head
            body = context.channel.allocator.buffer(capacity: 0)

        case .body(var incoming):
            guard let head = requestHead, var collected = body else {
                closing = true
                context.close(promise: nil)
                return
            }
            guard incoming.readableBytes <= bodyLimit - collected.readableBytes else {
                closing = true
                send(.text("request body too large\n", status: .payloadTooLarge),
                    for: head, on: context)
                return
            }
            collected.writeBuffer(&incoming)
            body = collected

        case .end:
            guard let head = requestHead, let collected = body else {
                closing = true
                context.close(promise: nil)
                return
            }
            requestHead = nil
            body = nil
            closing = true
            let request = WebRequest(head: head, body: Data(collected.readableBytesView))
            send(router.handle(request), for: head, on: context)
        }
    }

    private func send(
        _ reply: Reply,
        for request: HTTPRequestHead,
        on context: ChannelHandlerContext
    ) {
        let bytes = reply.payload
        var head = HTTPResponseHead(
            version: request.version,
            status: reply.status
        )
        for header in reply.headers {
            let key = header.name.lowercased()
            if !["content-type", "content-length", "connection", 
                "transfer-encoding"].contains(key) {
                head.headers.add(name: header.name, value: header.value)        
            }
        }
        head.headers.add(name: "content-type", value: reply.contentType)
        head.headers.add(name: "content-length", value: String(bytes.count))
        head.headers.add(name: "connection", value: "close")
        context.write(wrapOutboundOut(.head(head)), promise: nil)
        if request.method != .HEAD {
            var buffer = context.channel.allocator.buffer(capacity: bytes.count)
            buffer.writeBytes(bytes)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        }

        let done = context.eventLoop.makePromise(of: Void.self)
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: done)
        done.futureResult.whenComplete { _ in
            context.close(promise: nil)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        context.close(promise: nil)
    }
}
