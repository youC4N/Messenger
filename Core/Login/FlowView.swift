//
//  SwiftUIView.swift
//  Messenger
//
//  Created by Егор Малыгин on 07.05.2024.
//

import SwiftUI


struct FlowView: View {
    @State var flow = AppFlow.login
    
    var body: some View {
        switch flow {
        case .login:
            NavigationStack {
                PhoneNumberView(onLoginComplete: {
                    withAnimation {
                        flow = .regular
                    }
                })
            }
            .transition(.blurReplace)
        case .regular:
            NavigationStack {
                MainChatsView()
            }
            .transition(.slide)
        }
    }
}

#Preview {
    FlowView()
}
