//
//  Socket.swift
//  Pods
//
//  Created by Simon Manning on 23/06/2016.
//
//

import Foundation
import Starscream

public final class Socket {
    // MARK: - Convenience aliases
    public typealias Payload = [String: AnyObject]

    // MARK: - Properties

    private var socket: WebSocket
    public var enableLogging = true

    public var onConnect: (() -> ())?
    public var onDisconnect: (NSError? -> ())?

    private(set) public var channels: [String: Channel] = [:]

    private static let HeartbeatInterval = Int64(30 * NSEC_PER_SEC)
    private static let HeartbeatPrefix = "hb-"
    private var heartbeatQueue: dispatch_queue_t

    private var awaitingResponses = [String: Push]()

    public var isConnected: Bool {
        return socket.isConnected
    }

    // MARK: - Initialisation

    public init(url: NSURL, params: [String: String]? = nil, selfSignedSSL: Bool = false) {
        heartbeatQueue = dispatch_queue_create("com.ecksd.birdsong.hbqueue", nil)
        socket = WebSocket(url: buildURL(url, params: params))
        socket.delegate = self
        socket.selfSignedSSL = selfSignedSSL
    }

    public convenience init(url: String, params: [String: String]? = nil,
                            selfSignedSSL: Bool = false) {
        if let parsedURL = NSURL(string: url) {
            self.init(url: parsedURL, params: params, selfSignedSSL: selfSignedSSL)
        }
        else {
            print("[Birdsong] Invalid URL in init. Defaulting to localhost URL.")
            self.init()
        }
    }

    public convenience init(prot: String = "http", host: String = "localhost", port: Int = 4000,
                            path: String = "socket", transport: String = "websocket",
                            params: [String: String]? = nil, selfSignedSSL: Bool = false) {
        let url = "\(prot)://\(host):\(port)/\(path)/\(transport)"
        self.init(url: url, params: params, selfSignedSSL: selfSignedSSL)
    }

    // MARK: - Connection

    public func connect() {
        if socket.isConnected {
            return
        }

        log("Connecting to: \(socket.currentURL)")
        socket.connect()
    }

    public func disconnect() {
        if !socket.isConnected {
            return
        }

        log("Disconnecting from: \(socket.currentURL)")
        socket.disconnect()
    }

    // MARK: - Channels

    public func channel(topic: String, payload: Payload = [:]) -> Channel {
        let channel = Channel(socket: self, topic: topic, params: payload)
        channels[topic] = channel
        return channel
    }

    public func remove(channel: Channel) {
        channel.leave().receive("ok") { response in
            self.channels.removeValueForKey(channel.topic)
        }
    }

    // MARK: - Heartbeat

    func sendHeartbeat() {
        guard socket.isConnected else {
            return
        }

        let ref = Socket.HeartbeatPrefix + NSUUID().UUIDString
        send(Push(Event.Heartbeat, topic: "phoenix", payload: [:], ref: ref))
        queueHeartbeat()
    }

    func queueHeartbeat() {
        let time = dispatch_time(DISPATCH_TIME_NOW, Socket.HeartbeatInterval)
        dispatch_after(time, heartbeatQueue) { 
            self.sendHeartbeat()
        }
    }

    // MARK: - Sending data

    func send(event: String, topic: String, payload: Payload) -> Push {
        let push = Push(event, topic: topic, payload: payload)
        return send(push)
    }

    func send(message: Push) -> Push {
        do {
            let data = try message.toJson()
            log("Sending: \(message.payload)")
            awaitingResponses[message.ref!] = message
            socket.writeData(data)
        } catch let error as NSError {
            log("Failed to send message: \(error)")
            message.handleParseError()
        }

        return message
    }

    // MARK: - Event constants

    struct Event {
        static let Heartbeat = "heartbeat"
        static let Join = "phx_join"
        static let Leave = "phx_leave"
        static let Reply = "phx_reply"
        static let Error = "phx_error"
        static let Close = "phx_close"
    }
}

extension Socket: WebSocketDelegate {

    // MARK: - WebSocketDelegate

    public func websocketDidConnect(socket: WebSocket) {
        log("Connected to: \(socket.currentURL)")
        onConnect?()
        queueHeartbeat()
    }

    public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        log("Disconnected from: \(socket.currentURL)")
        onDisconnect?(error)

        // Reset state.
        awaitingResponses.removeAll()
        channels.removeAll()
    }

    public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        do {
            let data = text.dataUsingEncoding(NSUTF8StringEncoding)
            if let response = Response(data: data!) {
                defer {
                    awaitingResponses.removeValueForKey(response.ref)
                }

                log("Received message: \(response.payload)")

                if let push = awaitingResponses[response.ref] {
                    push.handleResponse(response)
                }

            channels[response.topic]?.received(response)
            }
        }
        catch {
            fatalError("Couldn't parse response: \(text)")
        }
    }

    public func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        log("Received data: \(data)")
    }
}

// MARK: - Logging

extension Socket {
    private func log(message: String) {
        if enableLogging {
            print("[Birdsong]: \(message)")
        }
    }
}

// MARK: - Private URL helpers

private func buildURL(url: NSURL, params: [String: String]?) -> NSURL {
    guard let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false),
        params = params else {
            return url
    }

    var queryItems = [NSURLQueryItem]()
    params.forEach({
        queryItems.append(NSURLQueryItem(name: $0, value: $1))
    })

    components.queryItems = queryItems
    return components.URL!
}