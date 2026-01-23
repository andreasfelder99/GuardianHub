//
//  GuardianHubApp.swift
//  GuardianHub
//
//  Created by Andreas Felder on 23.01.2026.
//

import SwiftUI
import SwiftData

@main
struct GuardianHubApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BreachCheck.self,
            BreachEvent.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // TODO: handle this better in production, maybe show error to user
            fatalError("[SwiftData]Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootNavigationView()
        }
        .modelContainer(sharedModelContainer)
    }
}
