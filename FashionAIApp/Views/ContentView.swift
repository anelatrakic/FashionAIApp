//
//  ContentView.swift
//  FashionAIApp
//
//  Created by Anela Trakic on 6/1/25.
//
//

import SwiftUI
import KeychainAccess

struct Option: Hashable {
    let title: String
    let imageName: String
}

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentOption = 0 //represents current tab we are on
    private let apiKey: String
    private let chatGPTAPI: ChatGPTAPI

    init() {
        // Uses macOS Keychain to secure API key
        let keychain = Keychain(service: "openai_api_key")
        self.apiKey = (try? keychain.get(NSUserName())) ?? ""
        self.chatGPTAPI = ChatGPTAPI(apiKey: apiKey)
    }
    
    let options: [Option] = [
        .init(title: "Home", imageName: "house"),
        .init(title: "New Chat", imageName: "tshirt"),
        //TODO: Add save functionality .init(title: "Saved", imageName: ""),
        .init(title: "About", imageName: "info.circle")
    ]
    
    var body: some View {
        NavigationView {
            // For the left side options
            ListView(
                options: options,
                currentSelection: $currentOption //$ notifies that it is a binding
            )
            
            switch currentOption {
                case 1:
                    ChatListView(api: chatGPTAPI)
                case 2:
                    AboutView()
                default:
                    HomeView()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .navigationTitle("FashionGPT")
    }
}

struct ListView: View {
    let options: [Option]
    //binding so we can change selection
    @Binding var currentSelection: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            //options.enumerated to track the index
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                HStack {
                    Image(systemName: option.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20)

                    Text(option.title)
                        .foregroundColor(currentSelection == index ? Color("Pink 2") : Color.black)

                    Spacer()
                }
                .padding(8)
                .contentShape(Rectangle()) // Makes the whole row tappable
                .onTapGesture {
                    currentSelection = index
                }
            }
            Spacer()
        }
    }
}
