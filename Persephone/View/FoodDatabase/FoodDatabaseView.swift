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
    
    struct FoodType: Identifiable, Hashable {
        var id: String {
            get { name }
        }
        
        let name: String
        let children: [FoodType]?
        
        init(_ name: String, children: [FoodType]? = nil) {
            self.name = name
            self.children = children
        }
        
        func containsTags(_ tags: [String]) -> Bool {
            (name == "None" && tags.isEmpty) || name == "All" || tags.contains(where: { containsTag($0) })
        }
        
        func containsTag(_ tag: String) -> Bool {
            name == "All" || name == tag || (children != nil && children!.contains(where: { $0.containsTag(tag) }))
        }
    }
    
    static let MainFoodTypes: [FoodType] = [
        .init("All"),
        .init("Alcohol", children: [
            .init("Beer"),
            .init("Sake"),
            .init("Spirits"),
            .init("Wine")
        ]),
        .init("Bread", children: [
            .init("Buns")
        ]),
        .init("Cereal"),
        .init("Chocolate"),
        .init("Condiment", children: [
            .init("Salt"),
            .init("Sauce")
        ]),
        .init("Cookies"),
        .init("Dairy", children: [
            .init("Cheese"),
            .init("Eggs"),
            .init("Ice Cream"),
            .init("Milk"),
            .init("Yogurt")
        ]),
        .init("Fruit"),
        .init("Ingredients", children: [
            .init("Baking Soda"),
            .init("Butter"),
            .init("Flour"),
            .init("Ginger"),
            .init("Honey"),
            .init("Mix"),
            .init("Sugar")
        ]),
        .init("Juice"),
        .init("Meat", children: [
            .init("Beef"),
            .init("Chicken"),
            .init("Pork")
        ]),
        .init("Pasta"),
        .init("Pastry"),
        .init("Rice"),
        .init("Snack", children: [
            .init("Granola"),
            .init("Granola Bar"),
            .init("Protein Bar")
        ]),
        .init("Soda"),
        .init("Tortilla"),
        .init("Vegetable", children: [
            .init("Broccoli"),
            .init("Green Beans"),
            .init("Onion"),
        ]),
        .init("None")
    ]
    
    enum ViewType: Hashable {
        case ItemsView(type: FoodType)
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
    @State private var selectedItem: FoodItem? = nil
    
    var body: some View {
        return NavigationStack(path: $path) {
            List {
                OutlineGroup(FoodDatabaseView.MainFoodTypes, id: \.name, children: \.children) { type in
                    NavigationLink(type.name, value: ViewType.ItemsView(type: type))
                }
            }
            .confirmationDialog("Are you sure?", isPresented: $showDeleteDialog) {
                Button("Delete", role: .destructive) {
                    if let selectedItem = selectedItem {
                        modelContext.delete(selectedItem)
                    }
                }
            } message: {
                Text("You cannot undo this action.")
            }
            .navigationTitle("Food Database")
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
    }
    
    private func editLink(item: FoodItem) -> some View {
        Button {
            path.append(.ItemEdit(item: item))
        } label: {
            Label("Edit", systemImage: "pencil.circle").tint(.blue)
        }
    }
    
    private func deleteButton(item: FoodItem) -> some View {
        Button {
            delete(item: item)
        } label: {
            Label("Delete", systemImage: "trash").tint(.red)
        }
    }
    
    private func delete(item: FoodItem) {
        showDeleteDialog = true
        selectedItem = item
    }
    
    private func handleNavigation(viewType: ViewType) -> some View {
        // TODO improve this
        VStack {
            switch viewType {
            case .ItemsView(let type):
                ItemsView(path: $path, foodType: type)
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

private struct ItemsView: View {
    @Query(sort: \FoodItem.name) var foodItems: [FoodItem]
    
    let foodType: FoodDatabaseView.FoodType
    
    @Binding private var path: [FoodDatabaseView.ViewType]
    @State private var search: String = ""
    
    init(path: Binding<[FoodDatabaseView.ViewType]>, foodType: FoodDatabaseView.FoodType) {
        self._path = path
        self.foodType = foodType
    }
    
    var body: some View {
        List(foodItems.filter({ foodType.containsTags($0.metaData.tags) && isSearchFiltered($0) })) { item in
            NavigationLink(value: FoodDatabaseView.ViewType.ItemView(item: item)) {
                VStack(alignment: .leading) {
                    Text(item.name)
                    HStack {
                        Text(item.metaData.brand ?? "Custom")
                            .font(.subheadline)
                            .fontWeight(.light)
                            .italic()
                        Spacer()
                        if !item.storeEntries.isEmpty {
                            Text("\(bestCostPerServing(item)) / \(item.size.servingSizeAmount.unit.getAbbreviation().lowercased())")
                                .font(.subheadline)
                                .fontWeight(.light)
                        }
                    }
                }.contextMenu {
                    Button {
                        path.append(.ItemEdit(item: item))
                    } label: {
                        Label("Edit", systemImage: "pencil.circle")
                    }
                } preview: {
                    FoodItemPreview(item: item)
                }
            }
        }.navigationTitle(foodType.name)
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
    }
    
    private func isSearchFiltered(_ item: FoodItem) -> Bool {
        search.isEmpty || item.name.contains(search) || (item.metaData.brand ?? "").contains(search)
    }
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    private func bestCostPerServing(_ item: FoodItem) -> String {
        currencyFormatter.string(for: item.storeEntries.map({ entry in entry.costPerServingAmount(size: item.size) }).sorted().first!)!
    }
}

#Preview {
    let container = createTestModelContainer()
    createTestFoodItem(container.mainContext)
    return FoodDatabaseView()
        .modelContainer(container)
}
