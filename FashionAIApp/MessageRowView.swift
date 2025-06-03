//
//  MessageRowView.swift
//  FashionAIApp
//
//  Created by Anela Trakic on 6/2/25.
//

import SwiftUI

struct MessageRowView: View {

    @Environment(\.colorScheme) private var colorScheme
    let message: MessageRow
    let retryCallback: (MessageRow) -> Void
    var body: some View {
        VStack(spacing: 0) {
            messageRow(text: message.sendText, image: message.sendImage, bgColor: colorScheme == .light ? .white : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5))
            
            Divider()
            messageRow(text: message.responseText,
                       image: message.responseImage,
                       bgColor: Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5),
                       responseError: message.responseError,
                       showDotLoading: message.isInteractingWithChatGPT)
            Divider()
            
        }
    }
    
    func messageRow(text: String, image: String, bgColor: Color, responseError: String? = nil, showDotLoading: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 24) {
            if image.hasPrefix("http"), let url = URL(string: image) {
                AsyncImage(url: url) { image in image.resizable().frame(width: 25, height: 25)
                } placeholder: { ProgressView() }
            } else {
                Image(image)
                    .resizable()
                    .frame(width: 25, height: 25)
            }
            
            VStack(alignment: .leading) {
                if !text.isEmpty {
                    Text(text)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                }
                
                if let error = responseError {
                    Text("Error: \(error)").multilineTextAlignment(.leading)
                    Button("Regenerate response") {
                        retryCallback(message)
                    }
                    .padding(.top)
                }
                
                if showDotLoading {
                    DotLoadingView()
                        .frame(width: 60, height: 30)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MessageRowView_Previews: PreviewProvider {
    static let message = MessageRow(
        isInteractingWithChatGPT: true,
        sendImage: "profile",
        sendText: "What is SwiftUI?",
        responseImage: "openai",
        responseText: "SwiftUI is Apple’s modern, declarative framework for building user interfaces across all its platforms: iOS, macOS, watchOS, and tvOS.",
        responseError: nil)
    
    static var previews: some View {
        NavigationStack {
            ScrollView {
                MessageRowView(message: message,
                               retryCallback: { messageRow in })
                .frame(width: 400)
                .previewLayout(.sizeThatFits)
            }
        }
    }
}
