import OSLog
import SwiftUI

struct MainChatsView: View {
    @State private var showingSheet = false
    @State var openedChat: Int?
    let initialUserID: Int
    var sessionToken: String
    // TODO: every time empty array with users
    @State var wrongSession: () -> Void
    @State var allChats: [User]?
    
    struct User: Equatable, Identifiable {
        var userName: String
        var id: Int
    }
    
    struct UserResponse: Codable {
        var user: [String: Int]
    }
    
    func getUserInfo(for initialID: Int, with sessionToken: String) async throws -> [String: Int] {
        let address = "http://127.0.0.1:8080/chatsOf/\(initialID)"
        let url = URL(string: address)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        guard let httpResponse = httpResponse as? HTTPURLResponse else {
            throw MYError.unknownURLresponse
        }
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
    
    func getPrivateChats(for sessionToken: String) async throws -> [User] {
        var resultUsers: [User] = []
        let allChatsInfo = try await getUserInfo(for: initialUserID, with: sessionToken)
        for oneUserInfo in allChatsInfo {
            let newChat = User(userName: oneUserInfo.key, id: oneUserInfo.value)
            resultUsers.append(newChat)
        }
        
        return resultUsers
    }
    
    var body: some View {
        List {
            if let allChats = allChats {
                ForEach(allChats) { chat in
                    HStack {
                        UserAvatar(sessionToken: sessionToken, userID: chat.id)
                            .padding(.trailing, 8)
                            
                        Text(chat.userName)
                            .fontWeight(.bold)
                            .font(.system(size: 50))
                            .minimumScaleFactor(0.01)
                            .foregroundStyle(.black)
                        Spacer()
                    }
                }
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
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    Task {
                        do {
                            let chats = try await getPrivateChats(for: sessionToken)
                            allChats = chats
                        } catch {
                            throw error
                        }
                    }
                }, label: {
                    Image(systemName: "arrow.clockwise")
                })
            }
        }
        .navigationTitle("Chats")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSheet) {
            NavigationStack {
                SearchForUserView(
                    sessionToken: sessionToken, wrongSession: wrongSession,
                    startedChat: { userID in openedChat = userID })
            }
        }
        .navigationDestination(item: $openedChat) { partisipant_b in
            MainVideoPlayerView(chat: partisipant_b, sessionToken: sessionToken)
        }
    }
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
