import SwiftUI

let API_BASE_URL = URL(string: "http://localhost:8080/")!

struct UserAvatar: View {
    var sessionToken: String
    var userID: Int
    @State var stage: Stage = .loading

    enum Stage {
        case loading, loaded(Image), error(any Error), stale(Image), notFound
    }

    @ViewBuilder
    var content: some View {
        switch stage {
        case .loading: Circle().backgroundStyle(.placeholder).opacity(0.8)
        case .loaded(let image): RoundAvatar(image: image)
        case .error(_): Circle().backgroundStyle(.placeholder)
        case .notFound: Circle().backgroundStyle(.placeholder)
        case .stale(let image): RoundAvatar(image: image).opacity(0.7)
        }
    }

    var body: some View {
        content.task(id: userID, priority: .medium) {
            do {
                if case .loaded(let previous) = stage {
                    withAnimation {
                        stage = .stale(previous)
                    }
                }
                var request = URLRequest(url: API_BASE_URL.appending(components: "user", String(userID), "avatar"))
                request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 404 {
                        stage = .notFound
                    }
                    if httpResponse.statusCode != 200 {
                        throw ImageLoadError(fromResponse: httpResponse, data: data)
                    }
                }
                if Task.isCancelled { return }
                guard let image = UIImage(data: data) else {
                    throw ImageDecodeError()
                }
                if Task.isCancelled { return }
                withAnimation {
                    stage = .loaded(Image(uiImage: image))
                }
            } catch {
                logger.error("Failed to load an image for user with id \(userID): \(error, privacy: .public)")
                stage = .error(error)
            }
        }
    }
}

enum ImageLoadError: Error {
    case binary(status: Int)
    case textual(status: Int, response: String)
    case recognized(status: Int, reason: String)
    
    init(fromResponse res: HTTPURLResponse, data: Data) {
        guard let text = String(data: data, encoding: .utf8) else {
            self = .binary(status: res.statusCode)
            return
        }
        struct RecognizedServerError: Decodable {
            var reason: String
        }
        guard let recognized = try? JSONDecoder().decode(RecognizedServerError.self, from: data) else {
            self = .textual(status: res.statusCode, response: text)
            return
        }
        self = .recognized(status: res.statusCode, reason: recognized.reason)
    }
}

struct RoundAvatar: View {
    var image: Image
    
    var body: some View {
        image.resizable()
            .aspectRatio(1, contentMode: .fill)
            .clipShape(Circle())
    }
}
