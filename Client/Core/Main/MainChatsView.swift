import SwiftUI

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

struct MainChatsView: View {
    @State private var users: [User] = []

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

        .navigationTitle("Chats")

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

}

#Preview {
    NavigationStack {
        MainChatsView()
    }
}
