//
//  Response.swift
//  Pods
//
//  Created by Simon Manning on 23/06/2016.
//
//

import Foundation

open class Response {
    open let ref: String
    open let topic: String
    open let event: String
    open let payload: Socket.Payload

    init?(data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as! Socket.Payload
            if let ref = jsonObject["ref"] as? String {
                self.ref = ref
            }
            else {
                self.ref = ""
            }
            topic = jsonObject["topic"] as! String
            event = jsonObject["event"] as! String
            payload = jsonObject["payload"] as! Socket.Payload
        }
        catch {
            return nil
        }
    }
}
