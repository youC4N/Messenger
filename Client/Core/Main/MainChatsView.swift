import SwiftUI
import OSLog



enum findUserResponse: Decodable, Hashable{
    case invalidSessionToken
    case userDoesntExist
    case userFound(username: String, id: Int)
}




func requestUser(withNumber number: String, sessionToken: String) async throws -> findUserResponse {
    let address = "http://127.0.0.1:8080/getUser/\(number)"
    //logger.info("address is -- \(address)")
    //print("address is -- \(address)")
    let url = URL(string: address)!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization" )
    let response = try await URLSession.shared.data(for: request)
    guard let httpResponse = response.1 as? HTTPURLResponse else {
        throw ServerRequestError.nonHTTPResponse(got: Mirror(reflecting: response).subjectType)
    }

    print("\(httpResponse.statusCode)")
    guard httpResponse.statusCode == 200 else {
        throw ServerRequestError.serverError(
            status: httpResponse.statusCode,
            message: String(data: response.0, encoding: .utf8)
        )
    }
    return try JSONDecoder().decode(findUserResponse.self, from: response.0)
}

func requstUserAvatar(for userID: Int, sessionToken: String) async throws -> Image? {
    let address = "http://127.0.0.1:8080/get/user/\(userID)/avatar"
    let url = URL(string: address)!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization" )
    let response = try await URLSession.shared.data(for: request)
    
    
    guard let httpResponse = response.1 as? HTTPURLResponse else {
        throw ServerRequestError.nonHTTPResponse(got: Mirror(reflecting: response).subjectType)
    }

    logger.info("Http response -- \(httpResponse.statusCode)")
    guard httpResponse.statusCode == 200 else {
        throw ServerRequestError.serverError(
            status: httpResponse.statusCode,
            message: ""
        )
    }
    //let a = UIImage(data: response.0)

    return Image(systemName: "person")
    
}

func getUsersInfo() async throws -> [User] {

    let endPoint = ""
    guard let url = URL(string: endPoint) else {
        throw MYError.invalidURL
    }
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw MYError.invalidResponse
    }
    do {
        let decoder = JSONDecoder()
        return try decoder.decode([User].self, from: data)
    } catch {
        throw MYError.invalidData
    }
}


struct SearchForUserView: View {
    @Environment(\.dismiss) var dismiss
    @State var phoneNumber = ""
    var sessionToken: String
    @State var userName: String?
    @State var userID: Int?
    @State var userImage: Image = Image(systemName: "person")
    @State var wrongSession: () -> Void
    @FocusState var focusedField:Bool?
    @State var errorMessage: String?
    @State var showAlert = false
    @State var alertMessage = ""
    @State var alertAction: (() -> Void)? = nil
    var countryCode = "+380"
    var countryFlag = "🇺🇦"
    

    func validate(_ code: String)  -> Bool {
        return code.allSatisfy{$0.isNumber} && code.count == 9
    }
    func handleFindUserResponse(_ res: findUserResponse){
        switch res {
        case .invalidSessionToken:
            alertMessage = "invalid session token"
            alertAction = {wrongSession()}
            showAlert = true
        case .userDoesntExist:
            alertMessage = "user with this \(phoneNumber) doesn't exist"
            showAlert = true
        case .userFound(let username, let id):
            userName = username
            userID = id
            alertMessage = "username -- \(username), ID -- \(id)"
            showAlert = true
        }
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
                                        handleFindUserResponse(response)
                                        print("userID -- \(userID)")
                                        guard let userID = userID else {throw MYError.noUserID}
                                        let avatarResponse = try await requstUserAvatar(for: userID, sessionToken: sessionToken)
                                        
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
            
            Section{
                HStack {
                    userImage
                        .resizable()
                        .frame(width: 48, height: 48)
                        .aspectRatio(1, contentMode: .fit)
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
                    NavigationLink("", destination: MainVideoPlayerView())
                        .opacity(0)
                )
                .padding()
                .frame(maxWidth: .infinity, maxHeight: 94)
                .background(.clear,in: RoundedRectangle(cornerRadius: 10))

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

struct MainChatsView: View {
    @State private var users: [User] = []
    @State private var showingSheet = false
    var sessionToken: String
    @State var wrongSession: () -> Void

    var body: some View {

        ScrollView {
            ForEach(users) { user in
                ContactCardView(userName: user.username)
            }
        }
        .task {
            do {
                users = try await getUsersInfo()

            } catch {
                print("invalid get users")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSheet.toggle()
                    print("add conversation")
                } label: {
                    Image(systemName: "square.and.pencil")
                }

            }
        }
        .navigationTitle("Chats")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSheet) {
            NavigationStack {
                SearchForUserView(sessionToken: sessionToken, wrongSession: wrongSession)
            }

        }

    }
}

struct User: Codable, Identifiable {
    var id: String { username }
    let username: String
}

enum MYError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case invalidGetUsers
    case noUserID

}

//#Preview {
//    NavigationStack {
//        MainChatsView()
//    }
//}
