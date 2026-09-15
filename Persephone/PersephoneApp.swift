//
//  PersephoneApp.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct PersephoneApp: App {
    let sharedModelContainer: ModelContainer = {
        do {
            return try PersephoneStore.makeAppContainer()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
                .onReceive(NotificationCenter.default.publisher(
                    for: ModelContext.didSave, object: sharedModelContainer.mainContext)) { _ in
                    WidgetCenter.shared.reloadTimelines(ofKind: PersephoneStore.daySummaryWidgetKind)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
