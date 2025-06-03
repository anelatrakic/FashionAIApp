//
//  AboutView.swift
//  FashionAIApp
//
//  Created by Anela Trakic on 6/3/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ZStack {
                    Color("Pink 1")
                        .ignoresSafeArea()

                    VStack(spacing: 24) {
                        Image("headshot")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            .overlay(
                                Circle().stroke(Color("Pink 2"), lineWidth: 3)
                            )

                        Text("About Me🤍✨")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color("Purple"))
                            .multilineTextAlignment(.center)

                        Text("""
                        Hi, I’m Anela! 👋  
                        
                        💡 I created this simple macOS app to start learning SwiftUI and explore integrating OpenAI APIs into applications. This project combines my interests in design, technology, and personal expression. Although simple, I learned a lot and can't wait to explore more with Swift and OpenAI APIs!
                        
                        📝 TODO: Use SwiftData to save convos & fashion advice
                        """)
                            .font(.body)
                            .foregroundColor(Color("Purple"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .frame(maxWidth: 600)
                }
    }
}
