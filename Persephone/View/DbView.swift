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
                            .navigationBarBackButtonHidden()
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
                            .navigationBarBackButtonHidden()
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
    container.mainContext.insert(FoodItem(timestamp: Date(), name: "Lightly Breaded Chicken Chunks", brand: "Kirkland", details: "Costco's chicken nuggets", price: 1399, store: "Costco", numServings: 16, servingSize: "4 oz", totalSize: 1814, sizeType: .Mass))
    return DbView()
        .modelContainer(container)
}
