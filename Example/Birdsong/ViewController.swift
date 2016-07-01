//
//  ViewController.swift
//  Birdsong
//
//  Created by Simon Manning on 06/30/2016.
//  Copyright (c) 2016 Simon Manning. All rights reserved.
//

import UIKit

import Birdsong

class ViewController: UIViewController {

    let socket = Socket(url: NSURL(string: "http://localhost:4000/socket/websocket")!)
    var channel: Channel?

    var lastMessageLabel: UILabel
    var sendMessageButton: UIButton
    var messageCount = 0

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        lastMessageLabel = UILabel()
        sendMessageButton = UIButton()

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        self.init(nibName: nil, bundle: nil)
    }

    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(lastMessageLabel)
        view.addSubview(sendMessageButton)

        let viewSize = view.frame.size

        lastMessageLabel.frame = CGRectMake(viewSize.width * 0.1,
                                            viewSize.height * 0.15,
                                            viewSize.width * 0.8,
                                            100)

        sendMessageButton.setTitle("Send test message", forState: .Normal)
        sendMessageButton.setTitleColor(UIColor.redColor(), forState: .Normal)
        sendMessageButton.addTarget(self,
                                    action: #selector(sendMessage),
                                    forControlEvents: .TouchUpInside)

        sendMessageButton.frame = CGRectMake(viewSize.width * 0.25,
                                             viewSize.height * 0.1,
                                             viewSize.width * 0.5,
                                             50)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // After connection, set up a channel and join it.
        socket.onConnect = {
            self.channel = self.socket.channel("rooms:birdsong", payload: ["user": "test"])

            self.channel?.on("new:msg", callback: { response in
                self.lastMessageLabel.text = "Received message: \(response.payload["body"]!)"
            })

            self.channel?.join().receive("ok", callback: { payload in
                self.lastMessageLabel.text = "Joined channel: \(self.channel!.topic)"
            }).receive("error", callback: { payload in
                self.lastMessageLabel.text = "Failed joining channel."
            })
        }

        // Connect!
        socket.connect()
    }

    func sendMessage() {
        self.channel?.send("new:msg", payload: ["body": "\(messageCount)"]).always {
            self.messageCount += 1
        }
    }
}

