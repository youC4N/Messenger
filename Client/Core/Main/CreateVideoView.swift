import AVFoundation
import AVKit
import MessengerInterface
import PhotosUI
import SwiftUI

struct TempVideo: Transferable {
    let fileURL: URL
    let type: VideoType
    
    enum VideoType {
        case mpeg4, quicktime
        
        init?(utType: UTType) {
            switch utType {
            case .mpeg4Movie: self = .mpeg4
            case .quickTimeMovie: self = .quicktime
            default: return nil
            }
        }
        
        var uttype: UTType {
            switch self {
            case .mpeg4: .mpeg4Movie
            case .quicktime: .quickTimeMovie
            }
        }
        
        var `extension`: String {
            switch self {
            case .mpeg4: "mp4"
            case .quicktime: "mov"
            }
        }
    }
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .mpeg4Movie) {
            SentTransferredFile($0.fileURL)
        } importing: {
            try copyToAppContainer(file: $0.file, fileType: .mpeg4)
        }
        FileRepresentation(contentType: .quickTimeMovie) {
            SentTransferredFile($0.fileURL)
        } importing: {
            try copyToAppContainer(file: $0.file, fileType: .quicktime)
        }
    }
    
    static func copyToAppContainer(file source: URL, fileType: VideoType) throws -> Self {
        logger.info("Copying temporary video asset to the app container \(source, privacy: .public)")
        let filename = "\(UUID()).\(fileType.extension)"
        let target = FileManager.default
            .temporaryDirectory
            .appending(component: filename, directoryHint: .notDirectory)
        try FileManager.default.copyItem(at: source, to: target)
        logger.info("Copied temporary video asset to \(target, privacy: .public)")
        return .init(fileURL: target, type: fileType)
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
    var recipient: UserID
    var sessionToken: SessionToken
    
    func handleUploadClick() {
        guard let selectedVideo else { return }
        
        Task { () async in
            do {
                let response = try await API.local.sendMessage(to: recipient, videoFile: selectedVideo.fileURL, sessionToken: sessionToken)
                logger.info("Message send reponse: \(String(reflecting: response))")
            } catch {
                logger.error("Error occurred while sending the video: \(error)")
            }
        }
    }

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
            Button(action: handleUploadClick) {
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
                    let types = selectedItem.supportedContentTypes.map { type in
                        (type.preferredMIMEType, type)
                    }
                    logger.info("Extracting video from photo started \(String(describing: types))")
                    isVideoProcessing = true
                    selectedVideo = try await selectedItem.loadTransferable(type: TempVideo.self)
                    isVideoProcessing = false
                    logger.info("Transcribed video \(String(describing: selectedVideo))")
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
    CreateVideoView(recipient: 3, sessionToken: "NOPE")
}
