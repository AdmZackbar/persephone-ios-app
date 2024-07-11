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
            DbView()
                .tabItem {
                    Label("DB", systemImage: "tablecells")
                }
            Text("Cookbook")
                .tabItem {
                    Label("Cookbook", systemImage: "book")
                }
            Text("Inventory")
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodItem.self, configurations: config)
    container.mainContext.insert(FoodItem(timestamp: Date(), name: "Lightly Breaded Chicken Chunks", brand: "Kirkland", details: "Costco's chicken nuggets", price: 1399, store: "Costco", numServings: 16, servingSize: "4 oz", totalSize: 1814, sizeType: .Mass))
    return MainView()
        .modelContainer(container)
}
