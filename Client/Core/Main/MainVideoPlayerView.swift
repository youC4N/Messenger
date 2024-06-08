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
        VStack {
            RoundedRectangle(cornerRadius: 10)
                .frame(width: 390, height: 700)
                .foregroundColor(.cyan)
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
            CreateVideoView(userBID: chat)
        }
    }
}

#Preview {
    NavigationStack {
        MainVideoPlayerView(chat: 1, sessionToken: "")
    }
}
