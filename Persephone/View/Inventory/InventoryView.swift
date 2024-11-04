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
    
    enum ViewType: Hashable {
        case AddItem
        case InstanceView(item: FoodInstance)
    }
    
    @State private var path: [ViewType] = []
    @State private var searchText: String = ""
    
    var body: some View {
        let items = foodInstances.filter({ isFiltered($0) })
        return NavigationStack(path: $path) {
            VStack {
                if items.isEmpty {
                    Text("No food on record")
                } else {
                    List(items, id: \.hashValue) { food in
                        NavigationLink(value: ViewType.InstanceView(item: food)) {
                            Text(food.foodItem.name)
                        }.contextMenu {
                            Button {
                                path.append(.InstanceView(item: food))
                            } label: {
                                Label("View", image: "magnifyingglass")
                            }
                            Button(role: .destructive) {
                                modelContext.delete(food)
                            } label: {
                                Label("Delete", image: "trash.fill")
                            }
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
                                path.append(.AddItem)
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
                .navigationDestination(for: ViewType.self, destination: handleNavigation)
        }
    }
    
    private func isFiltered(_ item: FoodInstance) -> Bool {
        if searchText.isEmpty {
            return true
        }
        return item.foodItem.name.localizedCaseInsensitiveContains(searchText)
    }
    
    @ViewBuilder
    private func handleNavigation(viewType: ViewType) -> some View {
        switch viewType {
        case .AddItem:
            AddFoodInstanceView(path: $path)
        case .InstanceView(let item):
            InventoryFoodView(item: item)
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    createTestFoodInstance(container.mainContext)
    return InventoryView()
        .modelContainer(container)
}
