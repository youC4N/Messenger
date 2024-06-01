import SwiftUI
import OSLog

let logger = Logger(subsystem: "com.github.youC4N.videomessenger", category: "UI")

@main
struct MessengerApp: App {
    var body: some Scene {
        WindowGroup {
            FlowDisambiguation()
        }
    }
}
