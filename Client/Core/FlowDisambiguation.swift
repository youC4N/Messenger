import SwiftUI

enum AppFlow: Codable, Hashable {
    case registration(registrationToken: String)
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
                }, onRegistrationRequired: {registrationToken in withAnimation {
                    currentFlow = .registration(registrationToken: registrationToken)
                }})
            }
            .transition(.blurReplace)
        case .regular:
            NavigationStack {
                MainChatsView()
            }
            .transition(.blurReplace)
        case .registration(registrationToken: let token):
            Registration(token: token, onLoginComplete: {
                withAnimation {
                    currentFlow = .regular
                }
            }).transition(.blurReplace)

            
            
        
        }
        
    }
}

#Preview {
    FlowDisambiguation()
}
