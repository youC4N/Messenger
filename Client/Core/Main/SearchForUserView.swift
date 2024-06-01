import SwiftUI

struct UserSearchMatch {
    var id: Int
    var username: String
    var phone: String
}

struct SearchForUserView: View {
    @Environment(\.dismiss) var dismiss
    @State var phoneNumber = ""
    var sessionToken: String
    @State var match: UserSearchMatch?
    @State var wrongSession: () -> Void
    @State var startedChat: (Int) -> Void
    @FocusState var focusedField: Bool?
    @State var alert: AlertOptions?
    var countryCode = "+380"
    var countryFlag = "🇺🇦"

    struct UserSearchResponse: Decodable {
        var id: Int
        var username: String
    }

    func handleSubmit() {
        guard validate(phoneNumber) else {
            match = nil
            return
        }
        Task {
            do {
                let fullPhone = "\(countryCode)\(phoneNumber)"
                let response = try await API.local.findUser(byPhoneNumber: fullPhone, sessionToken: sessionToken)
                switch response {
                case .unauthorized:
                    wrongSession()
                case .absent:
                    match = nil
                case .invalidPhoneNumber(reason: let reason):
                    logger.warning("Invalid phone number \(fullPhone, privacy: .private), as told by server: \(reason, privacy: .public)")
                    match = nil
                case .found(let user):
                    match = UserSearchMatch(
                        id: user.id,
                        username: user.username,
                        phone: fullPhone
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
    var sessionToken: String

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
                Text(match.phone)
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
            match: UserSearchMatch(id: 1, username: "John Appleseed", phone: "+380XXXXXXXXX"),
            sessionToken: "nope"
        )
    }
}
