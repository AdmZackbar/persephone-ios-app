//
//  PersephoneApp.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import SwiftUI
import SwiftData

@main
struct PersephoneApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(CurrentSchema.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
//            try tryAddDefaultCategories(container)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    private static func tryAddDefaultCategories(_ container: ModelContainer) throws {
        var query = FetchDescriptor<Category>()
        query.fetchLimit = 1
        guard try container.mainContext.fetch(query).isEmpty else { return }
        let categories: [Category] = [
            .init(name: "Meat", children: [
                .init(name: "Pork"),
                .init(name: "Chicken"),
                .init(name: "Turkey"),
                .init(name: "Beef"),
                .init(name: "Ham"),
                .init(name: "Bacon"),
                .init(name: "Fake Meat")
            ])
        ]
        for category in categories {
            container.mainContext.insert(category)
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }.modelContainer(sharedModelContainer)
    }
}
