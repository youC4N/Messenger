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
