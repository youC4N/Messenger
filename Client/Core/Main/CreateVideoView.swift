import AVFoundation
import AVKit
import MessengerInterface
import PhotosUI
import SwiftUI

enum NewMessageResponse: Codable {
    case unauthorized
    case success
}

struct TempVideo: Transferable {
    let fileURL: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .mpeg4Movie) {
            SentTransferredFile($0.fileURL)
        } importing: {
            TempVideo(fileURL: $0.file)
        }
    }
}

struct CreateVideoView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showVideoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var isVideoProcessing = false
    @State private var selectedVideo: TempVideo?
    @State private var offset = CGSize.zero
    @State private var showNextView = false
    var userBID: UserID

    var body: some View {
        VStack {
            ZStack {
                if let selectedVideo {
                    VideoPlayer(player: .init(url: selectedVideo.fileURL))
                }
                if isVideoProcessing {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            Button(action: { showVideoPicker = true }) {
                Image(systemName: "plus")
            }
            Button(action: {}) {
                Text("Send Video")
            }
        }
        .photosPicker(
            isPresented: $showVideoPicker,
            selection: $selectedItem,
            matching: .videos
        )
        .padding()
        .onChange(of: selectedItem) {
            guard let selectedItem else {
                selectedVideo = nil
                return
            }

            Task {
                do {
                    logger.info("Extracting video from photo started")
                    isVideoProcessing = true
                    selectedVideo = try await selectedItem.loadTransferable(type: TempVideo.self)
                    isVideoProcessing = false
                } catch {
                    logger.error(
                        "Error during extracting video from photo -- \(error.localizedDescription)")
                }
            }
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
                        case (-100...100, 0...):
                            offset = value.translation
                            print("down swipe")
                        default: print("no clue")
                        }
                    }
                }
                .onEnded { value in
                    switch (value.translation.width, value.translation.height) {
                    case (-100...100, 0...):
                        withAnimation(.spring) {
                            dismiss()
                        }
                        print("down swipe")
                    default: break
                    }
                    withAnimation(.spring) {
                        offset = .zero
                    }
                }
        )
    }
}

#Preview {
    CreateVideoView(userBID: 3)
}
