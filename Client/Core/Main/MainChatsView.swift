import SwiftUI

enum newChatResponse: Decodable, Hashable {
    case invalidNumber
    case sessionExpired
    case createNewChat
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
    @FocusState var focusedField:Bool?
    @State var showAlert = false
    var countryCode = "+380"
    var countryFlag = "🇺🇦"
    func validate(_ code: String)  -> Bool {
        return code.allSatisfy{$0.isNumber} && code.count != 9
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
                            if validate(phoneNumber){
                                
                            } else {
                                showAlert = true
                                // TODO: create alert
                                
                            }
                        }
                }
            }
            .onAppear{
                focusedField = true
            }
            .listRowBackground(Color.clear)
            
            Section{
                HStack {
                    Image(systemName: "person")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .aspectRatio(1, contentMode: .fit)
                        .foregroundColor(.primary)
                    Spacer()

                    Text("placeholder")
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
                SearchForUserView()
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

}

#Preview {
    NavigationStack {
        MainChatsView()
    }
}
