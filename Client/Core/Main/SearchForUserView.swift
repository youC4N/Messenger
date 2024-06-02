import SwiftUI
import MessengerInterface

struct UserSearchMatch {
    var id: UserID
    var username: String
    var phone: PhoneNumber
}

struct SearchForUserView: View {
    @Environment(\.dismiss) var dismiss
    @State var phoneNumber = ""
    var sessionToken: SessionToken
    @State var match: UserSearchMatch?
    @State var wrongSession: () -> Void
    @State var startedChat: (UserID) -> Void
    @FocusState var focusedField: Bool?
    @State var alert: AlertOptions?
    var countryCode = "+380"
    var countryFlag = "🇺🇦"

    struct UserSearchResponse: Decodable {
        var id: Int
        var username: String
    }

    func handleSubmit() {
        guard let phone = PhoneNumber(rawValue: "\(countryCode)\(phoneNumber)") else {
            match = nil
            return
        }
        Task {
            do {
                let response = try await API.local.findUser(byPhoneNumber: phone, sessionToken: sessionToken)
                switch response {
                case .unauthorized:
                    wrongSession()
                case .absent:
                    match = nil
                case .invalidPhoneNumber(reason: let reason):
                    logger.warning("Invalid phone number \(phone.description, privacy: .private), as told by server: \(reason, privacy: .public)")
                    match = nil
                case .found(let user):
                    match = UserSearchMatch(
                        id: user.id,
                        username: user.username,
                        phone: phone
                    )
                }
            } catch {
                // TODO: Show a pretty graphic maybe?
                logger.error("Unexpected error occured: \(error)")
            }
        }
    }

    func validate(_ code: String) -> Bool {
        return code.allSatisfy { $0.isNumber } && code.count == 9
    }

    var body: some View {
        List {
            Section {
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
                    TextField("number", text: $phoneNumber)
                        .padding(.leading, 10)
                        .frame(maxWidth: .infinity, maxHeight: 47)
                        .background(Color.secondary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .focused($focusedField, equals: true)
                        .keyboardType(.numbersAndPunctuation)
                        .onSubmit(handleSubmit)
                }
            }
            .onAppear {
                focusedField = true
            }
            .listRowBackground(Color.clear)
            if let match = match {
                Section {
                    Button {
                        startedChat(match.id)
                    }
                    label: {
                        UserSearchCard(match: match, sessionToken: sessionToken)
                    }
                }
            }
        }
        .navigationTitle("New Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

struct UserSearchCard: View {
    var match: UserSearchMatch
    var sessionToken: SessionToken

    var body: some View {
        HStack {
            UserAvatar(sessionToken: sessionToken, userID: match.id)
                .frame(width: 48, height: 48)
                .padding(.trailing, 4)

            VStack(alignment: .leading) {
                Text(match.username)
                    .multilineTextAlignment(.leading)
                    .fontWeight(.bold)
                    .font(.title3)
                    .foregroundStyle(.black)
                Text(match.phone.rawValue)
                    .foregroundStyle(.tertiary)
                    .font(.callout)
            }
            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    List {
        UserSearchCard(
            match: UserSearchMatch(
                id: UserID(rawValue: 1),
                username: "John Appleseed",
                phone: PhoneNumber(rawValue: "+380111111111")!
            ),
            sessionToken: SessionToken(rawValue: "nope")
        )
    }
}
