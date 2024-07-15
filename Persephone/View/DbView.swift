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
    @Query(sort: \FoodItem.name) var foodItems: [FoodItem]
    
    @State private var showDeleteDialog = false
    @State private var searchText = ""
    
    var body: some View {
        let filteredItems = foodItems.filter(isItemFiltered)
        return NavigationStack {
            List(filteredItems) { item in
                NavigationLink {
                    FoodItemView(item: item)
                } label: {
                    createListItem(item)
                }
                .contextMenu {
                    NavigationLink {
                        FoodItemView(item: item)
                    } label: {
                        Label("View", systemImage: "magnifyingglass")
                    }
                    editLink(item: item)
                    deleteButton()
                } preview: {
                    NutritionView(item: item)
                }
                .swipeActions {
                    deleteButton()
                    editLink(item: item)
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
            .overlay(Group {
                if (filteredItems.isEmpty) {
                    Text(foodItems.isEmpty ? "No food items in database." : "No food items found.")
                }
            })
            .navigationTitle("Food Database")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        NavigationLink {
                            ScanFoodView()
                        } label: {
                            Label("Scan Food", systemImage: "barcode.viewfinder")
                        }
                        NavigationLink {
                            FoodItemEditor(item: nil)
                        } label: {
                            Label("Add Custom Food", systemImage: "plus")
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Filter...")
    }
    
    private func createListItem(_ item: FoodItem) -> some View {
        VStack(alignment: .leading) {
            Text(item.name)
            if item.metaData.brand != nil || item.storeInfo != nil {
                Text(item.metaData.brand ?? item.storeInfo?.name ?? "")
                    .font(.subheadline)
                    .fontWeight(.light)
                    .italic()
            }
        }
    }
    
    private func isItemFiltered(item: FoodItem) -> Bool {
        searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText)
    }
    
    private func editLink(item: FoodItem) -> some View {
        NavigationLink {
            FoodItemEditor(item: item)
        } label: {
            Label("Edit", systemImage: "pencil.circle").tint(.blue)
        }
    }
    
    private func deleteButton() -> some View {
        Button(action: delete) {
            Label("Delete", systemImage: "trash").tint(.red)
        }
    }
    
    private func delete() {
        showDeleteDialog = true
    }
}

private let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1
    formatter.alwaysShowsDecimalSeparator = false
    return formatter
}()

private let currencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = 2
    return formatter
}()

private struct NutritionView: View {
    let item: FoodItem
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.name).font(.title2).fontWeight(.semibold)
            if (item.metaData.brand != nil || item.storeInfo != nil) {
                HStack {
                    Text(item.metaData.brand ?? "").font(.subheadline).italic()
                    Spacer()
                    Text(item.storeInfo?.name ?? "").font(.subheadline).italic()
                }
            }
            Divider()
            HStack {
                VStack(alignment: .leading) {
                    Text(item.storeInfo != nil ?
                         "\(currencyFormatter.string(for: Double(item.storeInfo!.price) / 100.0)!)" : "No Price")
                        .font(.title2).bold()
                    Text("Net Weight: \(format(item.sizeInfo.totalAmount))g")
                        .font(.subheadline)
                        .fontWeight(.light)
                    Text("\(format(item.sizeInfo.numServings)) Servings")
                        .font(.subheadline)
                        .fontWeight(.light)
                    Text("Serving: \(item.sizeInfo.servingSize) (\(format(item.sizeInfo.servingAmount))g)")
                        .font(.subheadline)
                        .fontWeight(.light)
                    Spacer()
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(format(item.composition.nutrients[.Energy])) Calories")
                        .font(.title2).bold()
                    Text("\(format(item.composition.nutrients[.TotalFat]))g Fat")
                        .font(.subheadline)
                        .fontWeight(.light)
                    Text("\(format(item.composition.nutrients[.TotalCarbs]))g Carbs")
                        .font(.subheadline)
                        .fontWeight(.light)
                    Text("\(format(item.composition.nutrients[.Protein]))g Protein")
                        .font(.subheadline)
                        .fontWeight(.light)
                    Spacer()
                }
            }
        }
        .padding()
    }
    
    private func format(_ value: Double?) -> String {
        formatter.string(for: value ?? 0.0)!
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodItem.self, configurations: config)
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
    return DbView()
        .modelContainer(container)
}
