import OSLog
import SwiftUI

let logger = Logger(subsystem: "com.github.youC4N.videomessenger", category: "UI")

@main
struct MessengerApp: App {
    var body: some Scene {
        WindowGroup {
            FlowDisambiguation()
//            NavigationStack {
//                MainChatsView(sessionToken: "2QflOn_NKjI-iBJDa9Wty", wrongSession: {})
//            }
        }
    }
}
