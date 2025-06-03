//
//  ChatListView.swift
//  FashionAIApp
//
//  Created by Anela Trakic on 6/3/25.
//

import SwiftUI

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
        .background(colorScheme == .light ? .white : Color("Purple"))
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
            
            TextField("Send message", text: $vm.inputMessage, axis: .vertical)
                .background(Color("Background").opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("Pink 2"), lineWidth: 1)
                )
                .cornerRadius(8)
                .focused($isTextFieldFocused)
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
                        .font(.system(size: 20))
                        .foregroundColor(Color("Pink 2"))
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
