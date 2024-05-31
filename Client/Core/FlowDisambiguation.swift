import SwiftUI
import OSLog


enum AppFlow: Codable, Hashable {
    
    case registration(registrationToken: String)
    case login
    case regular(session: String)
}

struct FlowDisambiguation: View {
    @State var currentFlow = AppFlow.login

    var body: some View {
        switch currentFlow {
        case .login:
            NavigationStack {
                PhoneNumberView(
                    onLoginComplete: { sessionToken in
                        withAnimation {
                            currentFlow = .regular(session: sessionToken)
                            
                        }
                    },
                    onRegistrationRequired: { registrationToken in
                        withAnimation {
                            currentFlow = .registration(registrationToken: registrationToken)
                        }
                    })
            }
            .transition(.blurReplace)
        case .regular(session: let sessionToken):
            NavigationStack {
                MainChatsView(sessionToken: sessionToken) {
                    currentFlow = .login
                }
            }
            .transition(.blurReplace)
        case .registration(registrationToken: let token):
            Registration(
                token: token,
                onLoginComplete: { sessionToken in
                    withAnimation {
                        currentFlow = .regular(session: sessionToken)
                    }
                }
            ).transition(.blurReplace)

        }

    }
}

#Preview {
    FlowDisambiguation()
}
