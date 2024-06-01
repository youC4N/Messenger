import SwiftUI
import OSLog








func requstUserAvatar(for userID: Int, sessionToken: String) async throws -> Image? {
    let address = "http://127.0.0.1:8080/user/\(userID)/avatar"
    let url = URL(string: address)!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization" )
    do {
        let (data, httpStatus) = try await URLSession.shared.data(for: request)
        guard let httpResponse = httpStatus as? HTTPURLResponse else {
            throw ServerRequestError.nonHTTPResponse(got: Mirror(reflecting: httpStatus).subjectType)
        }

        logger.info("Http response -- \(httpResponse.statusCode)")
        guard httpResponse.statusCode == 200 else {
            throw ServerRequestError.serverError(
                status: httpResponse.statusCode,
                message: ""
            )
        }
        guard let uiImage = UIImage(data: data) else {
            throw MYError.noAvatar
        }

        return Image(uiImage: uiImage)
    }
    catch {
        return Image(systemName: "person")
    }
    
    
    
}




struct MainChatsView: View {
    @State private var showingSheet = false
    @State var openedChat: Int?
    let initialUserID: Int
    var sessionToken: String
    @State var wrongSession: () -> Void
    
    struct User {
        var userName: String
        var id: Int
        var Image: Image?
    }
    
    struct UserResponse: Codable{
        var user: [String:Int]
    }
    
    
    func getUserInfo(for initialID: Int, with sessionToken: String) async throws -> [String:Int] {
        let address = "http://127.0.0.1:8080/chatsOf/\(initialID)"
        let url = URL(string: address)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization" )
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        guard let httpResponse = httpResponse as? HTTPURLResponse else {throw MYError.unknownURLresponse}
        guard httpResponse.statusCode == 200 else {
            switch httpResponse.statusCode {
            // TODO: finish swiftch statment for response
            default:
                throw MYError.unfinished
            }
        }
        let resDictionary = try JSONDecoder().decode(UserResponse.self, from: data)
        return resDictionary.user
    }
    
    func getAvatar(userIDs: some Sequence<Int>) -> [Image?]{
        for userID in userIDs {
            
        }
        return [nil]
    }

    
    func getPrivateChats(for sessionToken: String, in users: [User]) async throws -> Array<User> {
        var resultUsers = users
        let allChatsInfo = try await getUserInfo(for: initialUserID, with: sessionToken)
        let allAvatars = getAvatar(userIDs: allChatsInfo.values)
        for (oneUserInfo, oneAvatar) in zip(allChatsInfo, allAvatars) {
            if users.count >= 1 {
                // TODO: I need to check for exsiting user in users
            } else {
                resultUsers.append(User(userName: oneUserInfo.key, id: oneUserInfo.value, Image: oneAvatar))
            }
        }
        
        
        return [User(userName: "", id: 1)]
    }

    var body: some View {

        ScrollView {

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
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    Task{
                        do{
                            let response = try await getUserInfo(for: initialUserID, with: sessionToken)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }

            }
        }
        .navigationTitle("Chats")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSheet) {
            NavigationStack {
                SearchForUserView(sessionToken: sessionToken, wrongSession: wrongSession, startedChat: {userID in openedChat = userID})
            }
        }
        .navigationDestination(item: $openedChat){ partisipant_b in
            MainVideoPlayerView(chat: partisipant_b, sessionToken: sessionToken)
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
    case noAvatar
    case unknownURLresponse
    case unfinished

}

