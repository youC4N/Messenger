import SwiftUI



struct SearchForUserView: View {
    @Environment(\.dismiss) var dismiss
    @State var phoneNumber = ""
    var sessionToken: String
    @State var userName: String?
    @State var userID: Int?
    @State var userImage: Image = Image(systemName: "person")
    @State var wrongSession: () -> Void
    @State var startedChat: (Int) -> Void
    @FocusState var focusedField:Bool?
    @State var errorMessage: String?
    @State var showAlert = false
    @State var alertMessage = ""
    @State var alertAction: (() -> Void)? = nil
    var countryCode = "+380"
    var countryFlag = "🇺🇦"
    
    struct FindUserResponse: Codable {
        var username: String
        var id: Int
    }
    
    func requestUser(withNumber number: String, sessionToken: String) async throws -> FindUserResponse {
        let address = "http://127.0.0.1:8080/getUser/\(number)"
        let url = URL(string: address)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization" )
        let response = try await URLSession.shared.data(for: request)
        guard let httpResponse = response.1 as? HTTPURLResponse else {
            throw ServerRequestError.nonHTTPResponse(got: Mirror(reflecting: response).subjectType)
        }
        switch httpResponse.statusCode {
        case 200: break
        case 401:
            alertMessage = "invalid session token"
            alertAction = {wrongSession()}
            showAlert = true
        case 404:
            alertMessage = "user with this \(phoneNumber) doesn't exist"
            showAlert = true
        default:
            break
        }
        guard httpResponse.statusCode == 200 else {
            throw ServerRequestError.serverError(
                status: httpResponse.statusCode,
                message: String(data: response.0, encoding: .utf8)
            )
        }
        return try JSONDecoder().decode(FindUserResponse.self, from: response.0)
    }
    

    func validate(_ code: String)  -> Bool {
        return code.allSatisfy{$0.isNumber} && code.count == 9
    }

    var body: some View {
        List{
            Section{
                HStack{
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
                        .onSubmit() {
                            if validate("\(phoneNumber)"){
                                Task {
                                    do {
                                        let response = try await requestUser(withNumber: "\(countryCode)\(phoneNumber)", sessionToken: sessionToken)
                                        userName = response.username
                                        userID = response.id
                                        guard let avatarResponse = try await requstUserAvatar(for: response.id, sessionToken: sessionToken) else {
                                            userImage = Image(systemName: "person")
                                            throw MYError.noAvatar
                                        }
                                        
                                        userImage = avatarResponse
                                        
                                    }
                                    catch {
                                        logger.error("unexpected error occured: \(error)")
                                    }
                                }
                                
                            } else {
                                showAlert = true
                                alertMessage = "can't validate this number -- \(phoneNumber)"
                                // TODO: create alert
                                
                            }
                        }
                        .alert(isPresented: $showAlert) {
                            Alert(
                                title: Text("Notification"),
                                message: Text(alertMessage),
                                dismissButton: .default(Text("OK")) {
                                    if let action = alertAction {
                                        action()
                                    }
                                }
                            )
                        }
                }
            }
            .onAppear{
                focusedField = true
            }
            .listRowBackground(Color.clear)
            if userName != nil {
                Section{
                    HStack {
                        userImage
                            .resizable()
                            .frame(minWidth: 96, minHeight: 96)
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(Circle())
                            .foregroundColor(.primary)
                        Spacer()
                        
                        Text( userName ?? "placeholder")
                            .fontWeight(.bold)
                            .font(.system(size: 500))
                            .minimumScaleFactor(0.01)
                            .foregroundStyle(.black)
                        Spacer()
                        
                    }
                    .background(
                        Button(""){
                            dismiss()
                            if let userID = userID {
                                startedChat(userID)
                            }
                        }
                        .opacity(0)

                    )
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 94)
                    .background(.clear,in: RoundedRectangle(cornerRadius: 10))
                    
                    
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
