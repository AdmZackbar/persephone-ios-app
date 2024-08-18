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
                            LookupFoodView()
                        } label: {
                            Label("Lookup Food", systemImage: "magnifyingglass")
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
            Text(item.metaData.brand ?? "Custom")
                .font(.subheadline)
                .fontWeight(.light)
                .italic()
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
        VStack(alignment: .leading, spacing: 12) {
            Text(item.name)
                .font(.title)
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    if item.metaData.brand != nil {
                        Text(item.metaData.brand ?? "").font(.headline).italic()
                    }
                    if !item.metaData.tags.isEmpty {
                        Label(item.metaData.tags.joined(separator: ", "), systemImage: "tag.fill").font(.subheadline)
                    }
                }
            }
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("\(format(item.getNutrient(.Energy)?.value)) Calories")
                        .font(.title2).bold()
                    Text("\(format(item.getNutrient(.TotalFat)?.value))g Fat")
                        .font(.subheadline)
                        .fontWeight(.light)
                    Text("\(format(item.getNutrient(.TotalCarbs)?.value))g Carbs")
                        .font(.subheadline)
                        .fontWeight(.light)
                    Text("\(format(item.getNutrient(.Protein)?.value))g Protein")
                        .font(.subheadline)
                        .fontWeight(.light)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(item.size.servingSize) (\(format(item.size.servingAmount.value))\(item.size.servingAmount.unit.getAbbreviation()))").font(.headline).bold()
                    Text("\(formatter.string(for: item.size.numServings)!) servings").font(.subheadline)
                    Text("Net \(item.size.totalAmount.unit.isWeight() ? "Wt" : "Vol"): \(format(item.size.totalAmount.value)) \(item.size.totalAmount.unit.getAbbreviation())")
                        .font(.subheadline).fontWeight(.light)
                }
            }
            if item.details != nil {
                Text(item.details!).italic()
            }
            Spacer()
        }
        .padding()
    }
    
    private func format(_ value: FoodAmount.Value?) -> String {
        formatter.string(for: value?.toValue() ?? 0.0)!
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
