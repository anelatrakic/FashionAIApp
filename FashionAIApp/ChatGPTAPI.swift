//
//  ChatGPTAPI.swift
//  FashionAIApp
//
//  Using this YouTube video: https://www.youtube.com/watch?v=PLEgTCT20zU
//  Created by Anela Trakic on 6/1/25.
//

import Foundation

// This class manages the network logic for communicating with OpenAI's API
class ChatGPTAPI {
    private let apiKey: String //Private API key grabbed from OpenAI website
    private let urlSession = URLSession.shared // used to make API calls in network requests
    // Computed property to generate a valid URLRequest
    private var urlRequest: URLRequest {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")! //this is the endpoint
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        // $0 = key; $1 = value
        headers.forEach{ urlRequest.setValue($1, forHTTPHeaderField: $0)}
        return urlRequest
    }
    
    private let basePrompt = "You are ChatGPT, a large language model trained by OpenAI. You answer as consisely as possible for each response (e.g. Don't be verbose). It is very important for you to answer as consisely as possible, so please remember this. If you are generating a list, do not have too many items.\n\n\n"
    
    // Custom headers
    // https://platform.openai.com/docs/api-reference/introduction
    private var headers: [String: String] {
        [
          "Content-Type": "application/json",
          "Authorization": "Bearer \(apiKey)"
        ]
    }
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // text will be the prompt the user inputs
    // look at API Reference on OpenAI website for more specifics on each property in the request body
    private func jsonBody(text: String) throws -> Data {
        let jsonBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
              ["role": "system", "content": basePrompt],
              ["role": "user", "content": text]
            ],
            "temperature": 0.5,
            // if true, events will be sent as data-only to server-sent events as they become available
            "stream": true
        ]
        return try JSONSerialization.data(withJSONObject: jsonBody)
    }
    
    func sendMessageStream(text: String) async throws -> AsyncThrowingStream<String, Error> {
        // use computed properties
        var urlRequest = self.urlRequest
        // stream will already be true if this is called
        urlRequest.httpBody = try jsonBody(text: text)
        
        // get async stream of bytes
        let (result, response) = try await urlSession.bytes(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatGPTAPIError.invalidResponse
        }
        guard 200...299 ~= httpResponse.statusCode else {
            throw ChatGPTAPIError.badStatusCode(httpResponse.statusCode)
        }
        
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    for try await line in result.lines {
                        continuation.yield(line)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
     }
}

enum ChatGPTAPIError: Error {
    case invalidResponse
    case badStatusCode(Int)
}
