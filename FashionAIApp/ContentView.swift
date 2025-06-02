//
//  ContentView.swift
//  FashionAIApp
//
//  Created by Anela Trakic on 6/1/25.
//
//
//import SwiftUI
//import SwiftData
//

import SwiftUI
import KeychainAccess

struct ContentView: View {
    // Uses macOS Keychain to secure API key
    var apiKey: String {
        let keychain = Keychain(service: "openai_api_key")
        return (try? keychain.get(NSUserName())) ?? ""
    }

    var body: some View {
        VStack {
            Image(systemName: "globe").imageScale(.large).foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            Task {
                let api = ChatGPTAPI(apiKey: apiKey)
                do {
                    let stream = try await api.sendMessageStream(text: "What is James Bond")
                    for try await line in stream {
                        print(line)
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}
