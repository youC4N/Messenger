import MessengerInterface
import OSLog
import SwiftUI

struct MainChatsView: View {
    @State private var showingSheet = false
    @State var openedChat: UserID?
    var sessionToken: SessionToken
    @State var wrongSession: () -> Void

    @State var allChats: [User]?

    fileprivate func handleRefresh() {
        Task {
            do {
                switch try await API.local.fetchPrivateChats(sessionToken: sessionToken) {
                case .unauthorized: wrongSession()
                case .success(let users): allChats = users
                }
            } catch {
                logger.error("Couldn't fetch chats \(error, privacy: .public)")
            }
        }
    }

    var body: some View {
        ScrollView {
            let chats = allChats ?? []
            ForEach(chats) { chat in
                NavigationLink(
                    destination: MainVideoPlayerView(chat: chat.id, sessionToken: sessionToken, wrongSession: wrongSession)
                ) {
                    HStack {
                        UserAvatar(sessionToken: sessionToken, userID: chat.id)
                            .frame(width: 48, height: 48)
                            .padding(.trailing, 8)

                        Text(chat.username)
                            .fontWeight(.bold)
                            .font(.title3)
                            .minimumScaleFactor(0.01)
                            .foregroundStyle(.black)
                        Spacer()
                    }
                }
            }
        }
        .task {
            do {
                switch try await API.local.fetchPrivateChats(sessionToken: sessionToken) {
                case .unauthorized: wrongSession()
                case .success(let users): allChats = users
                }
            } catch {
                logger.error("Couldn't fetch chats \(error, privacy: .public)")
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
                Button(action: handleRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .navigationTitle("Chats")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSheet) {
            NavigationStack {
                SearchForUserView(
                    sessionToken: sessionToken, wrongSession: wrongSession,
                    startedChat: { userID in
                        showingSheet = false
                        openedChat = userID
                    })
            }
        }

        .navigationDestination(item: $openedChat) { partisipant_b in
            MainVideoPlayerView(chat: partisipant_b, sessionToken: sessionToken, wrongSession: wrongSession)
        }
    }
}

#Preview {
    MainChatsView(sessionToken: "", wrongSession: {})
}
