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
        Task { [self] in
            do {
                let message = try await send(message, relay: relay)
                print("response: \(String(describing: message))")
                NostrSendMessage.exit()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }

    /// メッセージの送信
    /// - Parameters:
    ///   - message: メッセージ
    ///   - relay: リレー
    /// - Returns: 結果
    private func send(_ message: String, relay: String) async throws -> URLSessionWebSocketTask.Message {
        try await withCheckedThrowingContinuation { continuation in
            let webSocketTask = URLSession(configuration: .default).webSocketTask(with: URL(string: relay)!)
            webSocketTask.resume()
            webSocketTask.send(.string(message)) {
                if let error = $0 {
                    continuation.resume(throwing: error)
                }
            }
            webSocketTask.receive {
                webSocketTask.cancel(with: .goingAway, reason: nil)
                switch $0 {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let message):
                    continuation.resume(returning: message)
                }
            }
        }
    }
}

/// 実行
NostrSendMessage.main()
RunLoop.current.run()
