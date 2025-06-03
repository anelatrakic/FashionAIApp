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
        .init(title: "Saved Fashion", imageName: "heart.fill"),
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
                    SavedFashionView()
                case 3:
                    AboutView()
                default:
                    HomeView()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        //chatListView.navigationTitle("FashionGPT")
    }
}

struct HomeView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 245/255, green: 243/255, blue: 240/255), Color(red: 220/255, green: 220/255, blue: 225/255)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "hanger")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.accentColor)
                    .padding()

                Text("Welcome to Your Own Virtual Closet!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Get fashion suggestions, save your favorite looks, and chat with your AI stylist🩷​​✨​🛍️👗")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

         
                Label("Click 'New Chat' on the top left to get started!", systemImage: "sparkles")
                    .padding()
                    .frame(maxWidth: 350)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
            }
            .padding()
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack {
            Text("TODO: Create a cool about page view")
        }
    }
}

struct SavedFashionView: View {
    var body: some View {
        VStack {
            Text("TODO: Create a cool page that saves the fashion advice")
        }
    }
}

struct ChatListView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var vm: ViewModel
    @FocusState var isTextFieldFocused: Bool

    init(api: ChatGPTAPI) {
        _vm = StateObject(wrappedValue: ViewModel(api: api))
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.messages) { message in
                            MessageRowView(message: message) { message in Task { @MainActor in
                                await vm.retry(message: message)
                            }
                            }
                        }
                    }
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                }
                
                Divider()
                bottomView(image: "profile", proxy: proxy)
                Spacer()
            }
            // so it keeps scrolling to the bottom as we go
            .onChange(of: vm.messages.last?.responseText) { _, _
                in scrollToBottom(proxy: proxy)
            }
        }
        .background(colorScheme == .light ? .white :
                        Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5))
    }
        
    func bottomView(image: String, proxy: ScrollViewProxy) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if image.hasPrefix("http"), let url = URL(string: image) {
                AsyncImage(url: url) { image in image.resizable().frame(width: 30, height: 30)
                } placeholder: { ProgressView() }
            } else {
                Image(image)
                    .resizable()
                    .frame(width: 30, height: 30)
            }
            
            TextField("Send message", text: $vm.inputMessage, axis: .vertical).textFieldStyle(.roundedBorder).focused($isTextFieldFocused)
                .disabled(vm.isInteractingWithChatGPT)
            
            if vm.isInteractingWithChatGPT {
                DotLoadingView().frame(width: 60, height: 30)
            } else {
                Button {
                    Task { @MainActor in
                        isTextFieldFocused = false
                        scrollToBottom(proxy: proxy)
                        await vm.sendTapped()
                    }
                } label: {
                    Image(systemName: "paperplane.circle.fill")
                        .rotationEffect(.degrees(45))
                        .font(.system(size: 30))
                }
                .disabled(vm.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let id = vm.messages.last?.id else { return }
        proxy.scrollTo(id, anchor: .bottomTrailing)
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
                        .foregroundColor(currentSelection == index ? Color.pink : Color.black)

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
