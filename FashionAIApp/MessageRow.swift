//
//  MessageRow.swift
//  FashionAIApp
//
//  Created by Anela Trakic on 6/2/25.
//

import SwiftUI
struct MessageRow: Identifiable {
    let id = UUID()
    
    var isInteractingWithChatGPT: Bool
    
    // sender (Us) and response (Chat)
    let sendImage: String
    let sendText: String
    
    let responseImage: String
    var responseText: String
    
    var responseError: String?
}
