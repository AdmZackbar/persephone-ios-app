//
//  DbView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import SwiftData
import SwiftUI

struct DbView: View {
    @Environment(\.modelContext) var modelContext
    @Query var foodItems: [FoodItem]
    
    @State private var showDeleteDialog = false
    
    var body: some View {
        NavigationStack {
            List(foodItems) { item in
                NavigationLink {
                    FoodItemView(item: item)
                } label: {
                    Text(item.name)
                }
                .swipeActions {
                    Button {
                        showDeleteDialog = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .tint(.red)
                    }
                    NavigationLink {
                        FoodItemEditor(item: item)
                    } label: {
                        Label("Edit", systemImage: "pencil.circle")
                            .tint(.blue)
                    }
                }
                .confirmationDialog("Are you sure?", isPresented: $showDeleteDialog) {
                    Button("Delete", role: .destructive) {
                        withAnimation {
                            modelContext.delete(item)
                        }
                    }
                } message: {
                    Text("You cannot undo this action.")
                }
            }
            .navigationTitle("Food Database")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        FoodItemEditor(item: nil)
                    } label: {
                        Label("Add Food...", systemImage: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodItem.self, configurations: config)
    let item = FoodItem(name: "Lightly Breaded Chicken Chunks",
                        metaData: FoodMetaData(
                            brand: "Kirkland",
                            details: "Costco's chicken nuggets"),
                        composition: FoodComposition(
                            calories: 120,
                            nutrients: [
                                .TotalCarbs: 4000,
                                .TotalSugars: 1500,
                                .TotalFat: 3000,
                                .SaturatedFat: 1250,
                                .Protein: 13000,
                                .Sodium: 530,
                                .Cholesterol: 25,
                            ],
                            ingredients: ["Salt", "Chicken", "Dunno"],
                        allergens: ["Meat"]),
                        sizeInfo: FoodSizeInfo(
                            numServings: 16,
                            servingSize: "4 oz",
                            totalAmount: 1814,
                            servingAmount: 63,
                            sizeType: .Mass),
                        storeInfo: StoreInfo(name: "Costco", price: 1399))
    container.mainContext.insert(item)
    return DbView()
        .modelContainer(container)
}
