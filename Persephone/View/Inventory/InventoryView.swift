//
//  InventoryView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/31/24.
//

import SwiftData
import SwiftUI

struct InventoryView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \FoodInstance.foodItem.name) var foodInstances: [FoodInstance]
    @Query(sort: \RecipeInstance.recipe.name) var recipeInstances: [RecipeInstance]
    
    @State private var searchText: String = ""
    
    var body: some View {
        let items = foodInstances
        return VStack {
            if items.isEmpty {
                Text("No food on record")
            } else {
                List(foodInstances, id: \.foodItem!.name) { food in
                    NavigationLink {
                        InventoryFoodView(item: food)
                    } label: {
                        Text(food.foodItem.name)
                    }
                }
            }
        }.searchable(text: $searchText)
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            // TODO
                        } label: {
                            Label("Add Food", systemImage: "fork.knife")
                        }
                        Button {
                            // TODO
                        } label: {
                            Label("Record Recipe", systemImage: "list.bullet.rectangle.portrait")
                        }
                    } label: {
                        Label("Add...", systemImage: "plus")
                    }
                }
            }
    }
}

#Preview {
    let container = createTestModelContainer()
    createTestFoodInstance(container.mainContext)
    return NavigationStack {
        InventoryView()
    }.modelContainer(container)
}
