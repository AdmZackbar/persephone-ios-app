//
//  MainView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import SwiftData
import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            FoodDatabaseView()
                .tabItem {
                    Label("Database", systemImage: "tablecells")
                }
            CookbookView()
                .tabItem {
                    Label("Cookbook", systemImage: "book")
                }
            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "list.clipboard")
                }
            Text("Logbook")
                .tabItem {
                    Label("Logbook", systemImage: "calendar")
                }
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    createTestFoodItem(container.mainContext)
    createTestRecipeItem(container.mainContext)
    return MainView()
        .modelContainer(container)
}
