//
//  Response.swift
//  Pods
//
//  Created by Simon Manning on 23/06/2016.
//
//

import Foundation

public class Response {
    public let ref: String
    public let topic: String
    public let event: String
    public let payload: Socket.Payload

    init?(data: NSData) {
        do {
            let jsonObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as! Socket.Payload
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