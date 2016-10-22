<p align="center">
    <img src="https://raw.githubusercontent.com/sjrmanning/Birdsong/assets/birdsong.png" width="483px" alt="Birdsong: Phoenix Channels WebSockets client for iOS & OS X">
</p>

# Birdsong

An iOS & OS X WebSockets client for use with [Phoenix](http://www.phoenixframework.org) [Channels](http://www.phoenixframework.org/docs/channels). Supports [Phoenix Presence](https://hexdocs.pm/phoenix/1.2.0/Phoenix.Presence.html)!

As of version 0.3.0, Birdsong requires Swift 3.0+. Please use version 0.2.2 if you need Swift 2.2 support.


## Usage

```swift
import Birdsong

…

let socket = Socket(url: NSURL(string: "http://localhost:4000/socket/websocket")!)

socket.onConnect = {
    let channel = self.socket.channel("rooms:some-topic", payload: ["user": "spartacus"])
    channel.on("new:msg", callback: { message in
        self.displayMessage(message)
    })

    channel.join().receive("ok", callback: { payload in
        print("Successfully joined: \(channel.topic)")
    })

    channel.send("new:msg", payload: ["body": "Hello!"])
        .receive("ok", callback: { response in
            print("Sent a message!")
        })
        .receive("error", callback: { reason in
            print("Message didn't send: \(reason)")
        })

    // Presence support.
    channel.presence.onStateChange = { newState in
        // newState = dict where key = unique ID, value = array of metas.
        print("New presence state: \(newState)")
    }

    channel.presence.onJoin = { id, meta in
        print("Join: user with id \(id) with meta entry: \(meta)")
    }

    channel.presence.onLeave = { id, meta in
        print("Leave: user with id \(id) with meta entry: \(meta)")
    }
}
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

Available on CocoaPods:

```ruby
platform :ios, '9.0'
use_frameworks!

pod 'Birdsong', '~> 0.4'
```

If you need Swift 2.2 compatibility, please use version `0.2.2`.

## Author

Simon Manning — [sjrmanning@github](https://github.com/sjrmanning)

## License

Birdsong is available under the MIT license. See the LICENSE file for more info.
