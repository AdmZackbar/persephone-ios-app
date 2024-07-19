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
                    Label("Database", systemImage: "tablecells")
                }
            CookbookView()
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
    let schema = Schema(CurrentSchema.models)
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let item = FoodItem(name: "Lightly Breaded Chicken Chunks",
                        metaData: FoodMetaData(
                            brand: "Kirkland"),
                        composition: FoodComposition(
                            nutrients: [
                                .Energy: 120,
                                .TotalCarbs: 4,
                                .TotalSugars: 1.5,
                                .TotalFat: 3,
                                .SaturatedFat: 1.25,
                                .Protein: 13,
                                .Sodium: 530,
                                .Cholesterol: 25,
                            ],
                            ingredients: "Salt, Chicken, Other stuff",
                        allergens: "Meat"),
                        sizeInfo: FoodSizeInfo(
                            numServings: 16,
                            servingSize: "4 oz",
                            totalAmount: 1814,
                            servingAmount: 63,
                            sizeType: .Mass),
                        storeInfo: StoreInfo(name: "Costco", price: 1399))
    container.mainContext.insert(item)
    return MainView()
        .modelContainer(container)
}
