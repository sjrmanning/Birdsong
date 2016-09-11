//
//  Message.swift
//  Pods
//
//  Created by Simon Manning on 23/06/2016.
//
//

import Foundation

open class Push {
    open let topic: String
    open let event: String
    open let payload: [String: AnyObject]
    let ref: String?

    var receivedStatus: String?
    var receivedResponse: Socket.Payload?

    fileprivate var callbacks: [String: [(Socket.Payload) -> ()]] = [:]
    fileprivate var alwaysCallbacks: [() -> ()] = []

    // MARK: - JSON parsing

    func toJson() throws -> Data {
        let dict = [
            "topic": topic,
            "event": event,
            "payload": payload,
            "ref": ref ?? ""
        ] as [String : Any]

        return try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions())
    }

    init(_ event: String, topic: String, payload: [String: AnyObject], ref: String = UUID().uuidString) {
        (self.topic, self.event, self.payload, self.ref) = (topic, event, payload, ref)
    }

    // MARK: - Callback registration

    open func receive(_ status: String, callback: @escaping (Socket.Payload) -> ()) -> Self {
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

    open func always(_ callback: @escaping () -> ()) -> Self {
        alwaysCallbacks.append(callback)
        return self
    }

    // MARK: - Response handling

    func handleResponse(_ response: Response) {
        receivedStatus = response.payload["status"] as! String
        receivedResponse = response.payload

        fireCallbacksAndCleanup()
    }

    func handleParseError() {
        receivedStatus = "error"
        receivedResponse = ["reason": "Invalid payload request." as AnyObject]

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
