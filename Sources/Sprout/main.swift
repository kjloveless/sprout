//
//  main.swift
//  sprout
//
//  Created by Kyle Loveless on 11/2/26.
//

import NIOCore
import NIOHTTP1
import NIOPosix

func run() throws {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    defer { try? group.syncShutdownGracefully() }

    let router = Router(assets: try Assets.load())

    let bootstrap = ServerBootstrap(group: group)
        .serverChannelOption(ChannelOptions.backlog, value: 128)
        .serverChannelOption(
            ChannelOptions.socketOption(.so_reuseaddr), 
            value: 1
        )
        .childChannelInitializer { channel in
            channel.pipeline.configureHTTPServerPipeline()
                .flatMap {
                    channel.pipeline.addHandler(HTTPHandler(router: router))
                }
        }

    let host = "127.0.0.1"
    let port = 8080
    let channel = try bootstrap.bind(host: host, port: port).wait()
    print("listening at http://\(host):\(port)")
    try channel.closeFuture.wait()
}

try run()
