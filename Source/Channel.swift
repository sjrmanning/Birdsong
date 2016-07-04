//
//  Channel.swift
//  Pods
//
//  Created by Simon Manning on 24/06/2016.
//
//

import Foundation

public class Channel {
    // MARK: - Convenience typealias

    public typealias Presence = [String: [String: AnyObject]]

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
        self.presence = [:]

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

    private func getPresenceMeta(entry: AnyObject) -> [String: AnyObject]? {
        guard let metas = entry["metas"] as? [[String: AnyObject]] else {
            return nil
        }

        return metas.first
    }

    private func presenceState(response: Response) {
        response.payload.forEach { id, dict in
            presence[id] = getPresenceMeta(dict)
        }

        presenceStateCallback?(presence)
    }

    private func presenceDiff(response: Response) {
        if let leaves = response.payload["leaves"] as? [String: AnyObject] {
            leaves.forEach { id, dict in
                presence.removeValueForKey(id)
            }
        }

        if let joins = response.payload["joins"] as? [String: AnyObject] {
            joins.forEach { id, dict in
                presence[id] = getPresenceMeta(dict)
            }
        }

        presenceStateCallback?(presence)
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

