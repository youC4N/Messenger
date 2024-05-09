//
//  MessengerApp.swift
//  Messenger
//
//  Created by Егор Малыгин on 19.04.2024.
//

import SwiftUI

enum AppFlow: Codable, Hashable {
    case login
    case regular
}

@main
struct MessengerApp: App {
    var body: some Scene {
        WindowGroup {
            FlowView()

        }
    }
}

