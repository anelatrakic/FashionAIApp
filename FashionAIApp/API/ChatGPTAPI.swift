//
//  ChatGPTAPI.swift
//  FashionAIApp
//
//  Created by Anela Trakic on 6/1/25.
//

import Foundation

// This class manages the network logic for communicating with OpenAI's API
class ChatGPTAPI {
    private let apiKey: String //Private API key grabbed from OpenAI website
    // Needed to maintain history of previous text asked/recieved
    // Because there is a maximum number of tokens, we do not want to store everything, so a threshold must be defined
    private var historyList = [String]()
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
    
    private let jsonDecoder = JSONDecoder()
    private let basePrompt = "You are FashionGPT, an expert fashion advisor trained by OpenAI. You specialize in fashion trends, personal styling, outfit coordination, wardrobe curation, and makeup advice. Always tailor your responses to be concise, helpful, and stylish. When recommending fashion or style choices, consider gender, body type, occasion, season, current trends, and cost. You can try to tailor your response using content from popular platforms like TikTok, Pinterest, and Instagram. Avoid being too generic and aim to give personalized, high-value advice.\n\n\n"
    
    // Custom headers
    // https://platform.openai.com/docs/api-reference/introduction
    private var headers: [String: String] {
        [
          "Content-Type": "application/json",
          "Authorization": "Bearer \(apiKey)"
        ]
    }
    
    private var historyListText: String {
        historyList.joined()
    }
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    private func generatePrompt(from text: String) -> String {
        var prompt = historyListText + text
        // One token = 4 chars
        if prompt.count > (4000 * 4) {
            _ = historyList.dropFirst()
            prompt = generatePrompt(from: text)
        }
        return prompt
    }
    // text will be the prompt the user inputs
    // look at API Reference on OpenAI website for more specifics on each property in the request body
    private func jsonBody(text: String, stream: Bool = true) throws -> Data {
        let jsonBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": generatePrompt(from: text)],
              ["role": "user", "content": text]
            ],
            "temperature": 0.5,
            // if true, events will be sent as data-only to server-sent events as they become available
            "stream": stream
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
        
        // Streaming version
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    var streamText = "" // to store history
                    for try await line in result.lines {
                        // Parse out "content" from stream
                        if line.hasPrefix("data: ") {
                            let dataString = line.dropFirst(6)
                            if let data = dataString.data(using: .utf8),
                               let response = try? self.jsonDecoder.decode(CompletionResponse.self, from: data),
                               let text = response.choices.first?.delta.content {
                                streamText += text
                                continuation.yield(text)
                            }
                        }
                    }
                    self.historyList.append(streamText)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // Returns complete response from Chat, will take longer
    // Non stream
    func sendMessage(_ text: String) async throws -> String {
        var urlRequest = self.urlRequest
        urlRequest.httpBody = try jsonBody(text: text, stream: false)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatGPTAPIError.invalidResponse
        }
        guard 200...299 ~= httpResponse.statusCode else {
            throw ChatGPTAPIError.badStatusCode(httpResponse.statusCode)
        }
        
        do {
            let completionResponse = try self.jsonDecoder.decode(FullCompletionResponse.self, from: data)
            let responseText = completionResponse.choices.first?.message.content ?? ""
            // to add history
            self.historyList.append(responseText)
            return responseText
        } catch {
            throw error
        }
    }
}

enum ChatGPTAPIError: Error {
    case invalidResponse
    case badStatusCode(Int)
}

// ex. This is the raw response recieved from the stream, and we need to decode it.
// data: {"id":"chatcmpl-BdzDpGed6i9QqqbGx00ThWcy507A7","object":"chat.completion.chunk","created":1748869829,"model":"gpt-4-0613","service_tier":"default","system_fingerprint":null,"choices":[{"index":0,"delta":{"content":"James"},"logprobs":null,"finish_reason":null}]}
struct CompletionResponse: Decodable {
    let choices: [Choice]
}
struct Choice: Decodable {
    let delta: Delta
}
struct Delta: Decodable {
    let content: String?
}

// When Stream is false, chat returns a different format
//{
//  "choices": [
//    {
//      "message": {
//        "role": "assistant",
//        "content": "full response here"
//      }
//    }
//  ]
//}
struct FullCompletionResponse: Decodable {
    let choices: [FullChoice]
}
struct FullChoice: Decodable {
    let message: FullMessage
}
struct FullMessage: Decodable {
    let role: String
    let content: String
}
