import Foundation
import MessengerInterface

extension API {
    func videoURL(ofMessage messageID: MessageID, inChatWith otherParticipantID: UserID, sessionToken: SessionToken) -> URL {
        endpoint
            .appending(components: "private-chat", String(otherParticipantID), "message", String(messageID), "video")
            .appending(queryItems: [.init(name: "sessionToken", value: sessionToken.rawValue)])
    }
}
