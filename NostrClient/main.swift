//
//  main.swift
//  NostrClient
//
//  Created by 本間大 on 2023/02/26.
//

import Foundation
import ArgumentParser
import NostrKit

/// デフォルトリレー
let defaultRelay: String = "wss://relay.damus.io"

/// Nostrクライアント
struct NostrSendMessage: ParsableCommand {
    /// プライベートキー
    @Argument(help: "PrivateKey(Hex) is required")
    var privateKey: String

    /// 内容
    @Argument(help: "Content is required")
    var content: String

    /// リレー
    @Option(help: "relay")
    var relay: String?

    /// 実行
    func run() throws {
        let event = try Event(keyPair: .init(privateKey: privateKey), content: content)
        let message = try ClientMessage.event(event).string()
        let relay = relay ?? defaultRelay
        print("message: \(message), relay: \(relay)")

        // 送信
        let webSocketTask = URLSession(configuration: .default).webSocketTask(with: URL(string: relay)!)
        webSocketTask.resume()
        webSocketTask.send(.string(message)) {
            if let error = $0 {
                fatalError(error.localizedDescription)
            }
        }
        webSocketTask.receive {
            webSocketTask.cancel(with: .goingAway, reason: nil)
            switch $0 {
            case .failure(let error):
                fatalError(error.localizedDescription)
            case .success(let message):
                print("response: \(message)")
                NostrSendMessage.exit()
            }
        }
    }
}

/// 実行
NostrSendMessage.main()
RunLoop.current.run()
