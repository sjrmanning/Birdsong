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

    let socket = Socket(url: URL(string: "http://localhost:4000/socket/websocket")!)
    var channel: Channel?

    var lastMessageLabel: UILabel
    var sendMessageButton: UIButton
    var messageCount = 0

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
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

        lastMessageLabel.frame = CGRect(x: viewSize.width * 0.1,
                                            y: viewSize.height * 0.15,
                                            width: viewSize.width * 0.8,
                                            height: 100)

        sendMessageButton.setTitle("Send test message", for: UIControlState())
        sendMessageButton.setTitleColor(UIColor.red, for: UIControlState())
        sendMessageButton.addTarget(self,
                                    action: #selector(sendMessage),
                                    for: .touchUpInside)

        sendMessageButton.frame = CGRect(x: viewSize.width * 0.25,
                                             y: viewSize.height * 0.1,
                                             width: viewSize.width * 0.5,
                                             height: 50)
    }

    override func viewDidAppear(_ animated: Bool) {
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

