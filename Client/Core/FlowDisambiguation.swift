import SwiftUI
import OSLog


enum AppFlow: Codable, Hashable {
    
    case registration(registrationToken: String)
    case login
    case regular(session: String, initialUserID: Int)
}

struct FlowDisambiguation: View {
    @State var currentFlow = AppFlow.login

    var body: some View {
        switch currentFlow {
        case .login:
            NavigationStack {
                PhoneNumberView(
                    onLoginComplete: { sessionToken, initialID in
                        withAnimation {
                            currentFlow = .regular(session: sessionToken, initialUserID: initialID)
                            
                        }
                    },
                    onRegistrationRequired: { registrationToken in
                        withAnimation {
                            currentFlow = .registration(registrationToken: registrationToken)
                        }
                    })
            }
            .transition(.blurReplace)
        case .regular(session: let sessionToken, initialUserID: let userID):
            NavigationStack {
                MainChatsView(initialUserID: userID, sessionToken: sessionToken) {
                    currentFlow = .login
                }
            }
            .transition(.blurReplace)
        case .registration(registrationToken: let token):
            Registration(
                token: token,
                onLoginComplete: { sessionToken, initialID in
                    withAnimation {
                        currentFlow = .regular( session: sessionToken, initialUserID: initialID)
                    }
                }
            ).transition(.blurReplace)

        }

    }
}

#Preview {
    FlowDisambiguation()
}
