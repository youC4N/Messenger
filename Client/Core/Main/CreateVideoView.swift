//
//  CreateVideoView.swift
//  MessengerClient
//
//  Created by Егор Малыгин on 07.06.2024.
//

import AVFoundation
import AVKit
import PhotosUI
import SwiftUI
import MessengerInterface

enum newMessageResponse: Codable {
    case unauthorized
    case success
}

struct VideoPickerTransferable: Transferable {
    let videoURL: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { exportingFile in
            return .init(exportingFile.videoURL)
        } importing: { received in
            let originaFile = received.file
            let copiedFile = URL.documentsDirectory.appending(path: "videoPicker.mov")
            if FileManager.default.fileExists(atPath: copiedFile.path()) {
                try FileManager.default.removeItem(at: copiedFile)
            }
            try FileManager.default.copyItem(at: originaFile, to: copiedFile)
            return .init(videoURL: copiedFile)
        }
    }
}
//extension API{
//    func sendVideo(sessionToken sessionToken: SessionToken,  userBID: Int, Video: Data) async throws -> newMessageResponse{
//        let url = endpoint
//            .appending(components: "private_chat", "\(userBID)", "video")
//
//        
//    }
//}

struct CreateVideoView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showVideoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var isVideoProcessing = false
    @State private var pickedVideoURL: URL?
    @State private var offset = CGSize.zero
    @State private var showNextView = false
    var userBID: Int

    var body: some View {

        VStack {
            ZStack {
                if let pickedVideoURL {
                    VideoPlayer(player: .init(url: pickedVideoURL))
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
            Button(
                action: {
                    showVideoPicker.toggle()
                },
                label: {
                    Image(systemName: "plus")
                }
            )
            Button(action: {
                deleteFile()
            }, label: {
                Image(systemName: "trash")
            })
            Button (action: {
                Task{
                    guard let selectedItem = selectedItem else {return}
                    let videoData = try await selectedItem.loadTransferable(type: Data.self)
                    print("video data = \(videoData)")
                }

            }, label: {
                Text("Send Video")
            })
        }
        .photosPicker(
            isPresented: $showVideoPicker, 
            selection: $selectedItem,
            matching: .videos
        )
        .padding()
        .onChange(of: selectedItem) { _, newValue in
            if let newValue {
                Task {
                    do {
                        logger.info("Extractiong video from photo started")
                        isVideoProcessing = true
                        let pickedMovie = try await newValue.loadTransferable(
                            type: VideoPickerTransferable.self)
                        isVideoProcessing = false
                        pickedVideoURL = pickedMovie?.videoURL
                    } catch {
                        logger.error("Error during extracting video from photo -- \(error.localizedDescription)")
                    }
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
                .onEnded{ value in
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
    
    func deleteFile() {
        do {
            if let pickedVideoURL {
                try FileManager.default.removeItem(at: pickedVideoURL)
                self.pickedVideoURL = nil
            }
            
        } catch {
            logger.error("Error while trying to delete -- \(error.localizedDescription)")
        }
    }
}


#Preview {
    CreateVideoView(userBID: 3)
}
