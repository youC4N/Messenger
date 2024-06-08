import AVFoundation
import AVKit
import MessengerInterface
import SwiftUI

struct MainVideoPlayerView: View {
    var chat: UserID
    var sessionToken: SessionToken
    @State private var offset = CGSize.zero
    @State private var showNextView = false

    var body: some View {
        let path =
            "https://drive.google.com/uc?export=download&id=1L4gWGi9WMr_lHA1Xrzd6xX1NK5Mma38T"
        let url = URL(string: path)!

        //VideoPlayer(player: AVPlayer(url: url))
        VStack {
            RoundedRectangle(cornerRadius: 10)
                .frame(width: 390, height: 700)
                .foregroundColor(.cyan)

            //            Button {
            //                Task {
            //                    do {
            //                        let address = "http://127.0.0.1:8080/chat/\(chat)"
            //                        let url = URL(string: address)!
            //                        var request = URLRequest(url: url)
            //                        request.httpMethod = "POST"
            //                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            //                        request.setValue(
            //                            "Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
            //                        logger.info("Successfully sent request for new chat creation")
            //                        let response = try await URLSession.shared.data(for: request)
            //                        guard let httpResponse = response.1 as? HTTPURLResponse else {
            //                            throw ServerRequestError.nonHTTPResponse(
            //                                got: Mirror(reflecting: response).subjectType)
            //                        }
            //                        guard httpResponse.statusCode == 200 else {
            //                            throw ServerRequestError(fromResponse: httpResponse, data: response.0)
            //                        }
            //                        logger.info("Chat created for user \(chat)")
            //                    } catch {
            //                        throw error
            //                    }
            //                }
            //            } label: {
            //                Text("Create chat with random user")
            //            }
        }
        .offset(offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    withAnimation(.spring()) {
                        switch (value.translation.width, value.translation.height) {
                        case (...0, -30...30): print("left swipe")
                        case (0..., -30...30): print("right swipe")
                        case (-100...100, ...0):
                            print("up swipe")
                            offset = value.translation
                        case (-100...100, 0...): print("down swipe")
                        default: print("no clue")
                        }

                    }

                }
                .onEnded({ value in
                    withAnimation(.spring) {
                        switch (value.translation.width, value.translation.height) {
                        case (-100...100, ...0):
                            withAnimation {
                                showNextView.toggle()
                            }

                        default: break
                        }
                        withAnimation {
                            offset = .zero
                        }
                    }
                })
        )
        .fullScreenCover(isPresented: $showNextView) {
            CreateVideoView(userBID: chat.rawValue)
        }
    }
}

#Preview {
    NavigationStack {
        MainVideoPlayerView(chat: 1, sessionToken: "")
    }
}
