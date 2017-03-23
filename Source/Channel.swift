//
//  Channel.swift
//  Pods
//
//  Created by Simon Manning on 24/06/2016.
//
//

import Foundation

open class Channel {
    // MARK: - Properties

    open let topic: String
    open let params: Socket.Payload
    fileprivate weak var socket: Socket?
    fileprivate(set) open var state: State

    fileprivate(set) open var presence: Presence

    fileprivate var callbacks: [String: (Response) -> ()] = [:]
    fileprivate var presenceStateCallback: ((Presence) -> ())?

    init(socket: Socket, topic: String, params: Socket.Payload = [:]) {
        self.socket = socket
        self.topic = topic
        self.params = params
        self.state = .Closed
        self.presence = Presence()

        // Register presence handling.
		on("presence_state") { [weak self] (response) in
			self?.presence.sync(response)
			guard let presence = self?.presence else {return}
			self?.presenceStateCallback?(presence)
		}
		on("presence_diff") { [weak self] (response) in
			self?.presence.sync(response)
		}
    }

    // MARK: - Control

    @discardableResult
    open func join() -> Push? {
        state = .Joining

        return send(Socket.Event.Join, payload: params)?.receive("ok", callback: { response in
            self.state = .Joined
        })
    }

    @discardableResult
    open func leave() -> Push? {
        state = .Leaving

        return send(Socket.Event.Leave, payload: [:])?.receive("ok", callback: { response in
            self.state = .Closed
        })
    }

    @discardableResult
    open func send(_ event: String,
                     payload: Socket.Payload) -> Push? {
        let message = Push(event, topic: topic, payload: payload)
        return socket?.send(message)
    }

    // MARK: - Raw events

    func received(_ response: Response) {
        if let callback = callbacks[response.event] {
            callback(response)
        }
    }

    // MARK: - Callbacks

    @discardableResult
    open func on(_ event: String, callback: @escaping (Response) -> ()) -> Self {
        callbacks[event] = callback
        return self
    }

    @discardableResult
    open func onPresenceUpdate(_ callback: @escaping (Presence) -> ()) -> Self {
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

