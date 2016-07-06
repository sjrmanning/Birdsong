//
//  Channel.swift
//  Pods
//
//  Created by Simon Manning on 24/06/2016.
//
//

import Foundation

public class Channel {
    // MARK: - Properties

    public let topic: String
    public let params: Socket.Payload
    private let socket: Socket
    private(set) public var state: State

    private(set) public var presence: Presence

    private var callbacks: [String: (Response) -> ()] = [:]
    private var presenceStateCallback: (Presence -> ())?

    init(socket: Socket, topic: String, params: Socket.Payload = [:]) {
        self.socket = socket
        self.topic = topic
        self.params = params
        self.state = .Closed
        self.presence = Presence(state: Presence.PresenceState())

        // Register presence handling.
        on("presence_state", callback: presenceState)
        on("presence_diff", callback: presenceDiff)
    }

    // MARK: - Control

    public func join() -> Push {
        state = .Joining

        return send(Socket.Event.Join, payload: params).receive("ok", callback: { response in
            self.state = .Joined
        })
    }

    public func leave() -> Push {
        state = .Leaving

        return send(Socket.Event.Leave, payload: [:]).receive("ok", callback: { response in
            self.state = .Closed
        })
    }

    public func send(event: String,
                     payload: Socket.Payload) -> Push {
        let message = Push(event, topic: topic, payload: payload)
        return socket.send(message)
    }

    // MARK: - Presence

    private func presenceState(response: Response) {
        presence.sync(response)

        presenceStateCallback?(presence)
    }

    private func presenceDiff(response: Response) {
        presence.sync(response)
    }

    // MARK: - Raw events

    func received(response: Response) {
        if let callback = callbacks[response.event] {
            callback(response)
        }
    }

    // MARK: - Callbacks

    public func on(event: String, callback: Response -> ()) -> Self {
        callbacks[event] = callback
        return self
    }

    public func onPresenceUpdate(callback: Presence -> ()) -> Self {
        presenceStateCallback = callback
        return self
    }

    // MARK: - States

    public enum State: String {
        case Closed = "closed"
        case Errored = "errored"
        case Joined = "joined"
        case Joining = "joining"
        case Leaving = "leaving"
    }
}

