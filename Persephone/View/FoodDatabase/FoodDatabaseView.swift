//
//  FoodDatabaseView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import SwiftData
import SwiftUI

struct FoodDatabaseView: View {
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
                    NavigationStack {
                        NutritionView(item: item)
                    }
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
            HStack {
                Text(item.metaData.brand ?? "Custom")
                    .font(.subheadline)
                    .fontWeight(.light)
                    .italic()
//                if (!item.storeItems.isEmpty) {
//                    Spacer()
//                    Text("\(currencyFormatter.string(for: Double(item.storeInfo!.price) / 100.0)!) @ \(item.storeInfo!.name)")
//                        .font(.subheadline)
//                        .fontWeight(.light)
//                        .italic()
//                }
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
    formatter.maximumFractionDigits = 2
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
            Text(item.name)
                .font(.title2)
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)
            if (item.metaData.brand != nil) {
                HStack {
                    Text(item.metaData.brand ?? "").font(.subheadline).italic()
//                    Spacer()
//                    Text(item.storeInfo?.name ?? "").font(.subheadline).italic()
                }
            }
            Divider()
            HStack {
                VStack(alignment: .leading) {
//                    Text(item.storeInfo != nil ?
//                         "\(currencyFormatter.string(for: Double(item.storeInfo!.price) / 100.0)!)" : "No Price")
//                        .font(.title2).bold()
//                    Text(item.size.sizeType == .Mass ? "Net Wt. \(formatWeight(item.sizeInfo.totalAmount))" : "Net Vol. \(formatVolume(item.sizeInfo.totalAmount))")
//                        .font(.subheadline)
//                        .fontWeight(.light)
                    Text("\(format(item.size.numServings)) Servings")
                        .font(.subheadline)
                        .fontWeight(.light)
                    Text("Serving: \(item.size.servingSize) (\(format(item.size.servingAmount.value))g)")
                        .font(.subheadline)
                        .fontWeight(.light)
                    Spacer()
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(format(item.getNutrient(.Energy)?.value ?? 0)) Calories")
                        .font(.title2).bold()
                    Text("\(format(item.getNutrient(.TotalFat)?.value ?? 0))g Fat")
                        .font(.subheadline)
                        .fontWeight(.light)
                    Text("\(format(item.getNutrient(.TotalCarbs)?.value ?? 0))g Carbs")
                        .font(.subheadline)
                        .fontWeight(.light)
                    Text("\(format(item.getNutrient(.Protein)?.value ?? 0))g Protein")
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
    
    private func formatVolume(_ volume: Double) -> String {
        if (volume > 500.0) {
            return "\(formatter.string(for: volume / 1000.0)!)L"
        }
        return "\(formatter.string(for: volume)!)mL"
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if (weight > 500.0) {
            return "\(formatter.string(for: weight / 1000.0)!)kg"
        }
        return "\(formatter.string(for: weight)!)g"
    }
}

#Preview {
    let container = createTestModelContainer()
    createTestFoodItem(container.mainContext)
    return FoodDatabaseView()
        .modelContainer(container)
}
