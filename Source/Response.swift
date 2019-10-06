//
//  Response.swift
//  Pods
//
//  Created by Simon Manning on 23/06/2016.
//
//

import Foundation

open class Response {
    public let ref: String
    public let topic: String
    public let event: String
    public let payload: Socket.Payload

    init?(data: Data) {
        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as? Socket.Payload else { return nil }
            
            ref = jsonObject["ref"] as? String ?? ""
            
            if let topic = jsonObject["topic"] as? String,
                let event = jsonObject["event"] as? String,
                let payload = jsonObject["payload"] as? Socket.Payload {
                self.topic = topic
                self.event = event
                self.payload = payload
            }
            else {
                return nil
            }
        }
        catch {
            return nil
        }
    }
}
