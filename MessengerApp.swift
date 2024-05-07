//
//  MessengerApp.swift
//  Messenger
//
//  Created by Егор Малыгин on 19.04.2024.
//

import SwiftUI

enum AppFlow: Codable, Hashable {
    case login
    case regular
}

@main
struct MessengerApp: App {
    var body: some Scene {
        WindowGroup {
            FlowView()
            
        }
    }
}

struct Prikolyamba: View {
    @State var rotation: Angle = .zero
    
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                Circle()
                    .foregroundStyle(Color.red)
                Circle()
                    .foregroundStyle(Color.white)
                    .padding()
                Text("卐")
                    .font(.system(size: 144))
                    .rotationEffect(rotation)
                    .frame(minWidth: 144, minHeight: 144)
            }
            Button(action: {
                withAnimation(.bouncy) {
                    rotation += .degrees(90)
                }
            }) {
                Text("Слава Україні")
            }
            Spacer()
        }
        
    }
}

//struct TransitionDemo: View {
//    
//    
//}



