import MessengerInterface
import SwiftUI
import AVKit
import AVFoundation

struct MainVideoPlayerView: View {
    var chat: UserID
    var sessionToken: SessionToken

    func getRandomNumber(to number: Int) -> Int {
        return Int.random(in: 2 ... number)
    }

    var body: some View {
        let path = "https://drive.google.com/uc?export=download&id=1L4gWGi9WMr_lHA1Xrzd6xX1NK5Mma38T"
        let url = URL(string: path)!
        VideoPlayer(player: AVPlayer(url: url))
        Button {
            Task {
                do {
                    let address = "http://127.0.0.1:8080/chat/\(chat)"
                    let url = URL(string: address)!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
                    logger.info("Successfully sent request for new chat creation")
                    let response = try await URLSession.shared.data(for: request)
                    guard let httpResponse = response.1 as? HTTPURLResponse else {
                        throw ServerRequestError.nonHTTPResponse(got: Mirror(reflecting: response).subjectType)
                    }
                    guard httpResponse.statusCode == 200 else {
                        throw ServerRequestError(fromResponse: httpResponse, data: response.0)
                    }
                    logger.info("Chat created for user \(chat)")
                }
                catch {
                    throw error
                }
            }
        } label: {
            Text("Create chat with random user")
        }
    }
}
