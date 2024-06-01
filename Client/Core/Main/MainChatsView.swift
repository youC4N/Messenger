import OSLog
import SwiftUI

func requstUserAvatar(for userID: Int, sessionToken: String) async throws -> Image? {
    let address = "http://127.0.0.1:8080/user/\(userID)/avatar"
    let url = URL(string: address)!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
    do {
        let (data, httpStatus) = try await URLSession.shared.data(for: request)
        guard let httpResponse = httpStatus as? HTTPURLResponse else {
            throw ServerRequestError.nonHTTPResponse(
                got: Mirror(reflecting: httpStatus).subjectType)
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
    } catch {
        return Image(systemName: "person")
    }

}

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
        var Image: Image?
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
    
    func getAvatar(userIDs: some Sequence<Int>) async throws -> [Int: Image?] {
        var res: [Int: Image] = [:]
        for userID in userIDs {
            res[userID] = try await requstUserAvatar(for: userID, sessionToken: sessionToken)
        }
        return res
    }
    
    func getPrivateChats(for sessionToken: String) async throws -> [User] {
        var resultUsers: [User] = []
        let allChatsInfo = try await getUserInfo(for: initialUserID, with: sessionToken)
        let allAvatars = try await getAvatar(userIDs: allChatsInfo.values)
        for (oneUserInfo, oneAvatar) in zip(allChatsInfo, allAvatars) {
            // TODO: I need to check for exsiting user in users
            let newChat = User(userName: oneUserInfo.key, id: oneUserInfo.value, Image: oneAvatar.value)
            if !resultUsers.contains(newChat){
                resultUsers.append(newChat)
            }
        }
        
        return resultUsers
    }
    
    func foo() async throws -> Void {
        
    }
    
    
    
    var body: some View {
        
        ScrollView{
            if allChats != nil {
                ForEach(allChats!){chat in
                    Section{
                        HStack {
                            if let image = chat.Image {
                                image
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .aspectRatio(1, contentMode: .fit)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person")
                            }
                            Spacer()
                            
                            Text( chat.userName ?? "placeholder")
                                .fontWeight(.bold)
                                .font(.system(size: 50))
                                .minimumScaleFactor(0.01)
                                .foregroundStyle(.black)
                            Spacer()
                            
                        }
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
                        Button (action :{
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
