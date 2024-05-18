import OSLog
import SwiftUI

struct PasswordRequest: Codable {
    let phoneNumber: String
}

let logger = Logger(subsystem: "com.github.youC4N.videomessenger", category: "UI")

struct PhoneNumberView: View {
    func validate(_ code: String) -> Bool {
        // TODO: validate the code
        return false
    }

    var countryCode = "+380"
    var countryFlag = "🇺🇦"
    @State var phoneNumber = ""
    var onLoginComplete: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Confirm country code and enter phone number")
                .font(.title)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button(action: {}) {
                    Text("\(countryFlag) \(countryCode)")
                        .padding(10)
                        .frame(minWidth: 80, minHeight: 48)
                        .background(
                            .secondary,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .foregroundColor(.black)
                }
                PhoneNumberField(text: $phoneNumber)
                    .padding(.leading, 10)
                    .frame(minWidth: 80, maxHeight: 48)
                    .background(
                        .secondary, in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .onSubmit {
                        if validate(phoneNumber) {
                            Task {
                                do {
                                    try await requestOTP(forPhoneNumber: phoneNumber)
                                } catch let e {
                                    
                                }
                            }
                        } else {
                            // TODO:
                        }
                    }

            }

            NavigationLink(destination: CodeView(onLoginComplete: onLoginComplete)) {
                Text("Next")
                    .frame(maxWidth: .infinity, minHeight: 47)
                    .background(
                        .secondary,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

        }

        .navigationTitle("Login")
        .padding(.horizontal)
        .padding(.bottom, 80)

    }
}

enum ServerRequestError: Error, CustomStringConvertible {
    case nonHTTPResponse(got: Any.Type)
    case serverError(status: Int, message: String?)
    
    var description: String {
        
    }
}

func requestOTP(forPhoneNumber phone: String) async throws -> OTPResponse {
    let address = "http://127.0.0.1:8080/otp"
    let url = URL(string: address)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(OTPRequest(number: phone))
    let (body, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw ServerRequestError.nonHTTPResponse(got: Mirror(reflecting: response).subjectType)
    }
    guard httpResponse.statusCode == 200 else {
        throw ServerRequestError.serverError(
            status: httpResponse.statusCode,
            message: String(data: body, encoding: .utf8)
        )
    }
    return try JSONDecoder().decode(OTPResponse.self, from: body)
}

struct OTPRequest: Codable {
    var number: String
}

enum OnClientErrors: Error {
    case WrongURLRequest
}

struct OTPResponse: Codable {
    var otpToken: String
}

#Preview {
    NavigationStack {
        PhoneNumberView(onLoginComplete: {})
    }
}
