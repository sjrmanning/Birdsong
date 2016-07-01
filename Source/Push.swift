//
//  Message.swift
//  Pods
//
//  Created by Simon Manning on 23/06/2016.
//
//

import Foundation

public class Push {
    public let topic: String
    public let event: String
    public let payload: [String: AnyObject]
    let ref: String?

    var receivedStatus: String?
    var receivedResponse: Socket.Payload?

    private var callbacks: [String: [(Socket.Payload) -> ()]] = [:]
    private var alwaysCallbacks: [() -> ()] = []

    // MARK: - JSON parsing

    func toJson() throws -> NSData {
        let dict = [
            "topic": topic,
            "event": event,
            "payload": payload,
            "ref": ref ?? ""
        ]

        return try NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions())
    }

    init(_ event: String, topic: String, payload: [String: AnyObject], ref: String = NSUUID().UUIDString) {
        (self.topic, self.event, self.payload, self.ref) = (topic, event, payload, ref)
    }

    // MARK: - Callback registration

    public func receive(status: String, callback: (Socket.Payload) -> ()) -> Self {
        if (receivedStatus == status) {
            callback(receivedResponse!)
        }
        else {
            if (callbacks[status] == nil) {
                callbacks[status] = [callback]
            }
            else {
                callbacks[status]?.append(callback)
            }
        }

        return self
    }

    public func always(callback: () -> ()) -> Self {
        alwaysCallbacks.append(callback)
        return self
    }

    // MARK: - Response handling

    func handleResponse(response: Response) {
        receivedStatus = response.payload["status"] as! String
        receivedResponse = response.payload

        fireCallbacksAndCleanup()
    }

    func handleParseError() {
        receivedStatus = "error"
        receivedResponse = ["reason": "Invalid payload request."]

        fireCallbacksAndCleanup()
    }

    func fireCallbacksAndCleanup() {
        defer {
            callbacks.removeAll()
            alwaysCallbacks.removeAll()
        }

        guard let status = receivedStatus else {
            return
        }

        alwaysCallbacks.forEach({$0()})

        if let matchingCallbacks = callbacks[status] {
            matchingCallbacks.forEach({$0(receivedResponse!)})
        }
    }
}
