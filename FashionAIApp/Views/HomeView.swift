//
//  HomeView.swift
//  FashionAIApp
//
//  Created by Anela Trakic on 6/3/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "hanger")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(Color("Pink 2"))
                    .padding()

                Text("Welcome to Your Own Virtual Closet!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("Purple"))
                    .multilineTextAlignment(.center)

                Text("Get fashion suggestions, save your favorite looks, and chat with your AI stylist🩷​​✨​🛍️👗")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(Color("Purple"))
         
                Label("Click 'New Chat' on the top left to get started!", systemImage: "sparkles")
                    .padding()
                    .frame(maxWidth: 350)
                    .background(Color("Pink 2"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
            }
            .padding()
        }
    }
}
