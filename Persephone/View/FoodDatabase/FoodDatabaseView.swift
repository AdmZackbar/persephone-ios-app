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
    
    enum ViewType: Hashable {
        case ItemView(item: FoodItem)
        case ItemAdd
        case ItemEdit(item: FoodItem)
        case ItemConfirm(item: FoodItem)
        case ScanItem
        case LookupItem
        case ExportItems(items: [FoodItem])
    }
    
    @State private var path: [ViewType] = []
    @State private var showDeleteDialog = false
    @State private var searchText = ""
    
    var body: some View {
        let filteredItems = foodItems.filter(isItemFiltered)
        return NavigationStack(path: $path) {
            List(filteredItems) { item in
                Button {
                    path.append(.ItemView(item: item))
                } label: {
                    createListItem(item).tint(.primary)
                }
                .contextMenu {
                    Button {
                        path.append(.ItemView(item: item))
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
                        Button {
                            path.append(.ScanItem)
                        } label: {
                            Label("Scan Food", systemImage: "barcode.viewfinder")
                        }
                        Button {
                            path.append(.LookupItem)
                        } label: {
                            Label("Lookup Food", systemImage: "magnifyingglass")
                        }
                        Button {
                            path.append(.ItemAdd)
                        } label: {
                            Label("Add Custom Food", systemImage: "plus")
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        path.append(.ExportItems(items: foodItems))
                    } label: {
                        Label("Export Database", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationDestination(for: ViewType.self, destination: handleNavigation)
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
        Button {
            path.append(.ItemEdit(item: item))
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
    
    private func handleNavigation(viewType: ViewType) -> some View {
        // TODO improve this
        VStack {
            switch viewType {
            case .ItemView(let item):
                FoodItemView(path: $path, item: item)
            case .ItemAdd:
                FoodItemEditor(path: $path)
            case .ItemEdit(let item):
                FoodItemEditor(path: $path, item: item)
            case .ItemConfirm(let item):
                FoodItemEditor(path: $path, item: item, mode: .Confirm)
            case .ScanItem:
                ScanFoodView(path: $path)
            case .LookupItem:
                LookupFoodView(path: $path)
            case .ExportItems(let items):
                FoodDatabaseExportView(foodItems: items)
            }
        }
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
            if !item.details.isEmpty {
                Text(item.details).italic()
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
