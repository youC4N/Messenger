import SwiftUI

let API_BASE_URL = URL(string: "http://localhost:8080/")!

struct UserAvatar: View {
    var sessionToken: SessionToken
    var userID: UserID
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
                if Task.isCancelled { return }
                
                let nextStage: Stage
                switch try await API.local.fetchAvatar(ofUser: userID, sessionToken: sessionToken) {
                case .unauthorized:
                    logger.warning("Tried to load a UserAvatar with an invalid session token \(sessionToken.description, privacy: .private)")
                    nextStage = .error(ServerRequestError.recognizedServerError(status: 401, reason: "Invalid session token."))
                case .notFound:
                    nextStage = .notFound
                case .success(let data):
                    guard let image = UIImage(data: data) else {
                        throw ImageDecodeError()
                    }
                    if Task.isCancelled { return }
                    nextStage = .loaded(Image(uiImage: image))
                }
                withAnimation {
                    stage = nextStage
                }
            } catch {
                logger.error("Failed to load an image for user with id \(userID): \(error, privacy: .public)")
                stage = .error(error)
            }
        }
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
