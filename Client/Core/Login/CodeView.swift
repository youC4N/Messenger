import MessengerInterface
import OSLog
import SwiftUI

struct AlertOptions: Identifiable {
    var id: String { "Couldn't authorize" }
    var message: String
    var action: (() -> Void)?
}

struct CodeView: View {
    @State var code = ""
    @State var response: LoginResponse?
    @State var alert: AlertOptions?

    var onLoginComplete: (SessionToken, UserID) -> Void
    var onExpired: () -> Void
    var onRegistrationRequired: (RegistrationToken) -> Void

    let otpToken: OTPToken

    func handleNextClick() {
        Task {
            do {
                let response = try await API.local.authenticate(forCode: code, otpToken: otpToken)
                switch response {
                case .expired:
                    alert = AlertOptions(
                        message: "The code has expired. Please request a new one.",
                        action: onExpired
                    )
                case .invalid:
                    alert = AlertOptions(
                        message: "The code you entered is invalid. Please try again."
                    )
                case .success(.existingLogin(sessionToken: let token, userID: let userID)):
                    onLoginComplete(token, userID)
                case .success(
                    .registrationRequired(registrationToken: let registrationToken, phone: _)):
                    onRegistrationRequired(registrationToken)
                }
            } catch {
                alert = AlertOptions(
                    message: "An error occurred: \(error.localizedDescription)"
                )
            }
        }
    }

    var body: some View {
        VStack {
            Text("Enter the code")
            HStack {
                ZStack {
                    TextField("", text: $code)
                        .padding(.leading, 10)
                        .frame(maxWidth: 160, minHeight: 47)
                        .background(Color.secondary, in: RoundedRectangle(cornerRadius: 10))
                        .autocorrectionDisabled(true)
                }
            }

            Button(action: handleNextClick) {
                Text("Next")
                    .frame(maxWidth: .infinity, minHeight: 47)
                    .background(
                        Color.secondary,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
            }
        }
        .padding()
        .navigationTitle("Authorization")
        .alert(item: $alert) { opts in
            Alert(
                title: Text("Couldn't authorize"),
                message: Text(opts.message),
                dismissButton: .default(Text("OK")) {
                    opts.action?()
                }
            )
        }
    }
}
