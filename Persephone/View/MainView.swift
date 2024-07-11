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
    let item = FoodItem(name: "Lightly Breaded Chicken Chunks", metaData: FoodMetaData(brand: "Kirkland", details: "Costco's chicken nuggets"), composition: FoodComposition(nutrients: [.Calorie: 120, .Protein: 13]), sizeInfo: FoodSizeInfo(numServings: 16, servingSize: "4 oz", totalAmount: 1814, servingAmount: 63, sizeType: .Mass), storeInfo: StoreInfo(name: "Costco", price: 1399))
    container.mainContext.insert(item)
    return MainView()
        .modelContainer(container)
}
