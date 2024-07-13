import AVFoundation
import AVKit
import MessengerInterface
import SwiftUI

struct MainVideoPlayerView: View {
    var chat: UserID
    var sessionToken: SessionToken
    @State private var offset = CGSize.zero
    @State private var showNextView = false
    @State private var counter = 0
    @State var wrongSession: () -> Void
    @State private var messages: [MYMessage]? = nil
    @State var urls: [URL] = []
    @State var showVP = false

    fileprivate func handleFetchMessages() {
        Task {
            do {
                switch try await API.local.fetchPrivateMessages(
                    byIDB: chat, sessionToken: sessionToken)
                {
                case .unauthorized:
                    wrongSession()
                case .success(let array):
                    logger.info("Successfully got chats from server")
                    messages = array
                    if let messages = messages {
                        urls = messages.map {
                            API.local.videoURL(
                                ofMessage: $0.id, inChatWith: chat, sessionToken: sessionToken)
                        }
                    }
                }
                logger.info("Got urls on messages \(urls)")
                if !urls.isEmpty {
                    showVP.toggle()
                }

            } catch {
                logger.error("Couldn't fetch messages \(error, privacy: .public)")
            }
        }
    }

    var body: some View {
        VStack {

            if !urls.isEmpty {
                VideoPlayer(player: AVPlayer(url: urls[counter]))
                    .frame(height: 400)
            }

            Button("get messages") {
                handleFetchMessages()
            }
            Button("create message") {
                showNextView.toggle()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if counter != 0 {
                        counter -= 1
                    }
                } label: {
                    Text("Previous")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if urls.count > counter && urls.count > counter + 1 {
                        logger.info(
                            "counter ++ next message: counter: \(counter) urls.count: \(urls.count)"
                        )
                        counter += 1
                    } else {
                        logger.info("No more messages")
                    }
                } label: {
                    Text("Next")
                }
            }

        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Messages")
        .offset(offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    withAnimation(.spring()) {
                        switch (value.translation.width, value.translation.height) {
                        case (-10...10, ...0):
                            print("up swipe")
                            offset = value.translation
                        default: print("no clue")
                        }

                    }

                }
                .onEnded({ value in
                    withAnimation(.spring) {
                        switch (value.translation.width, value.translation.height) {
                        case (-100...100, 0...):
                            print("down swipe")
                            if urls.count > counter && urls.count > counter + 1 {
                                logger.info(
                                    "counter ++ next message: counter: \(counter) urls.count: \(urls.count)"
                                )
                                counter += 1
                            } else {
                                logger.info("No more messages")
                            }
                        case (-10...10, ...0):
                            if counter != 0 {
                                counter -= 1
                            } else {
                                withAnimation {
                                    showNextView.toggle()
                                }
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
            CreateVideoView(recipient: chat, sessionToken: sessionToken)
        }
    }
}

#Preview {
    NavigationStack {
        MainVideoPlayerView(chat: 1, sessionToken: "", wrongSession: {})
    }
}
