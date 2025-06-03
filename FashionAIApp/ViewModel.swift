//
//  ViewModel.swift
//  FashionAIApp
//
//  Created by Anela Trakic on 6/2/25.
//

import Foundation
import SwiftUI

class ViewModel: ObservableObject {
    
    // Determine whether we are interacting with ChatGPT and if true, we disabled send button
    @Published var isInteractingWithChatGPT = false
    @Published var messages: [MessageRow] = []
    @Published var inputMessage: String = ""
    
    private let api: ChatGPTAPI
    
    init (api: ChatGPTAPI) {
        self.api = api
    }
    
    // MainActor runs functions on the main thread to avoid running in background thread
    @MainActor
    func sendTapped() async {
        let text = inputMessage
        inputMessage = ""
        await send(text: text)
    }
    
    // Incase response throws an error
    @MainActor
    func retry(message: MessageRow) async {
        guard let index = messages.firstIndex(where: {$0.id == message.id}) else {
                return
            }
        self.messages.remove(at: index)
        await send(text: message.sendText)
    }
    
    @MainActor
    private func send(text: String) async {
        isInteractingWithChatGPT = false
        var streamText = ""
        var messageRow = MessageRow(
            isInteractingWithChatGPT: true,
            sendImage: "profile",
            sendText: text,
            responseImage: "openai",
            responseText: streamText,
            responseError: nil)
        
        self.messages.append(messageRow)
        
        do {
            let stream = try await api.sendMessageStream(text: text)
            for try await text in stream {
                streamText += text
                // format correctly with trimmingCharacters
                messageRow.responseText = streamText.trimmingCharacters(in: .whitespacesAndNewlines)
                // when user sends message, we want to block send message, so they cannot send 2 messages in parallel
                self.messages[self.messages.count - 1] = messageRow
            }
        } catch {
            messageRow.responseError = error.localizedDescription
        }
        
        messageRow.isInteractingWithChatGPT = false
        self.messages[self.messages.count - 1] = messageRow
        isInteractingWithChatGPT = false
    }
}
