import SwiftUI

enum AppFlow: Codable, Hashable {
    case login
    case regular
}

struct FlowDisambiguation: View {
    @State var currentFlow = AppFlow.login

    var body: some View {
        switch currentFlow {
        case .login:
            NavigationStack {
                PhoneNumberView(onLoginComplete: {
                    withAnimation {
                        currentFlow = .regular
                    }
                })
            }
            .transition(.blurReplace)
        case .regular:
            NavigationStack {
                MainChatsView()
            }
            .transition(.blurReplace)
        }
    }
}

#Preview {
    FlowDisambiguation()
}
