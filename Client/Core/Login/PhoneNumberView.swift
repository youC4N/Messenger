import MessengerInterface
import SwiftUI

struct PasswordRequest: Codable {
    let phoneNumber: String
}

struct PhoneNumberView: View {
    @State var otpToken: OTPToken?
    var countryCode = "+380"
    var countryFlag = "🇺🇦"

    @State var phoneNumber = ""
    var onLoginComplete: (SessionToken, UserID) -> Void
    var onRegistrationRequired: (RegistrationToken) -> Void

    func validate(_ code: String) -> Bool {
        return code.count == 9 && code.allSatisfy { $0.isASCII && $0.isNumber }
    }

    var body: some View {
        VStack(spacing: 10) {
            Text("Confirm country code and enter phone number")
                .font(.title)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button(action: {}) {
                    Text("\(self.countryFlag) \(self.countryCode)")
                        .padding(10)
                        .frame(minWidth: 80, minHeight: 48)
                        .background(
                            .placeholder,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .foregroundColor(.black)
                }
                PhoneNumberField(text: self.$phoneNumber)
                    .padding(.leading, 10)
                    .frame(minWidth: 80, maxHeight: 48)
                    .background(
                        .placeholder, in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
            }
            Button(
                action: {
                    if let validPhone = PhoneNumber(rawValue: "\(countryCode)\(phoneNumber)") {
                        Task {
                            do {
                                switch try await API.local.requestOTP(forPhoneNumber: validPhone) {
                                case .invalidPhoneNumber(reason: _): break  // TODO: Display an error to the user
                                case .success(let payload): self.otpToken = payload.otpToken
                                }
                            } catch let e {
                                logger.error(
                                    "when requesting otp an error occured: \(e, privacy: .public)"
                                )
                            }
                        }
                    } else {
                        // TODO: Display an error to the user
                    }
                },
                label: {
                    Text("Next")
                        .frame(maxWidth: .infinity, minHeight: 47)
                        .background(
                            .secondary,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                }
            )
            .navigationDestination(item: self.$otpToken) { token in
                CodeView(
                    onLoginComplete: self.onLoginComplete,
                    onExpired: { self.otpToken = nil },
                    onRegistrationRequired: self.onRegistrationRequired,
                    otpToken: token
                )
            }
            .navigationTitle("Login")
            .padding(.bottom, 80)
        }
        .padding()
    }
}

#Preview {
    PhoneNumberView(otpToken: nil, onLoginComplete: { _, _ in }, onRegistrationRequired: { _ in })
}
