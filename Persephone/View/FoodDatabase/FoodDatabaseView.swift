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
            name == "All" || tags.contains(where: { containsTag($0) })
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
        .init("Carbs", children: [
            .init("Bread", children: [
                .init("Buns")
            ]),
            .init("Cereal"),
            .init("Crackers"),
            .init("Fries"),
            .init("Pasta"),
            .init("Rice"),
            .init("Tortilla")
        ]),
        .init("Condiment", children: [
            .init("BBQ Sauce"),
            .init("Ketchup"),
            .init("Maple Syrup"),
            .init("Salt"),
            .init("Sauce")
        ]),
        .init("Dairy", children: [
            .init("Cheese"),
            .init("Eggs"),
            .init("Ice Cream"),
            .init("Milk"),
            .init("Yogurt")
        ]),
        .init("Fruit", children: [
            .init("Apple"),
            .init("Berries"),
            .init("Grapes"),
            .init("Orange")
        ]),
        .init("Ingredients", children: [
            .init("Baking Soda"),
            .init("Butter"),
            .init("Flour"),
            .init("Ginger"),
            .init("Mix"),
            .init("Olive Oil"),
        ]),
        .init("Juice"),
        .init("Meat", children: [
            .init("Bacon"),
            .init("Beef"),
            .init("Chicken"),
            .init("Pork"),
            .init("Turkey")
        ]),
        .init("Snack", children: [
            .init("Granola"),
            .init("Granola Bar"),
            .init("Protein Bar")
        ]),
        .init("Soda"),
        .init("Sweets", children: [
            .init("Chocolate"),
            .init("Cookies"),
            .init("Honey"),
            .init("Pastry"),
            .init("Sugar")
        ]),
        .init("Vegetable", children: [
            .init("Broccoli"),
            .init("Green Beans"),
            .init("Onion"),
        ])
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
    
    @ViewBuilder
    private func handleNavigation(viewType: ViewType) -> some View {
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

private struct ItemsView: View {
    @Query(sort: \FoodItem.name) var foodItems: [FoodItem]
    
    enum SortType: Identifiable, CaseIterable {
        var id: String {
            get { getName() }
        }
        
        case Name
        case Brand
        case DateAdded
        
        func getName() -> String {
            switch self {
            case .Name:
                "Name"
            case .Brand:
                "Brand"
            case .DateAdded:
                "Date Added"
            }
        }
    }
    
    enum SortDirection: Identifiable, CaseIterable {
        var id: String {
            get { getIcon() }
        }
        
        case Ascending
        case Descending
        
        func getIcon() -> String {
            switch self {
            case .Ascending:
                "arrow.up"
            case .Descending:
                "arrow.down"
            }
        }
    }
    
    let foodType: FoodDatabaseView.FoodType
    
    @Binding private var path: [FoodDatabaseView.ViewType]
    @State private var search: String = ""
    @State private var sortType: SortType = .Name
    @State private var sortDirection: SortDirection = .Ascending
    
    init(path: Binding<[FoodDatabaseView.ViewType]>, foodType: FoodDatabaseView.FoodType) {
        self._path = path
        self.foodType = foodType
    }
    
    var body: some View {
        List(foodItems.filter({ foodType.containsTags($0.metaData.tags) && isSearchFiltered($0) })
            .sorted(by: {
                switch sortDirection {
                case .Ascending:
                    switch sortType {
                    case .Name:
                        $0.name < $1.name
                    case .Brand:
                        $0.metaData.brand ?? "" < $1.metaData.brand ?? ""
                    case .DateAdded:
                        $0.metaData.timestamp < $1.metaData.timestamp
                    }
                case .Descending:
                    switch sortType {
                    case .Name:
                        $0.name > $1.name
                    case .Brand:
                        $0.metaData.brand ?? "" > $1.metaData.brand ?? ""
                    case .DateAdded:
                        $0.metaData.timestamp > $1.metaData.timestamp
                    }
                }
            })) { item in
            NavigationLink(value: FoodDatabaseView.ViewType.ItemView(item: item)) {
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.headline)
                            .bold()
                        HStack {
                            Text(item.metaData.brand ?? "Generic")
                                .font(.subheadline)
                                .fontWeight(.light)
                                .italic()
                            Spacer()
                            if let rating = item.metaData.rating,
                               let tier = FoodTier.fromRating(rating: rating) {
                                Text("\(tier.rawValue) Tier")
                                    .font(.subheadline)
                                    .bold()
                            }
                        }
                    }
                    if let storeEntry = findBestStoreEntry(item) {
                        HStack(alignment: .bottom, spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(storeEntry.costPerServing(size: item.size).toString())
                                    .font(.subheadline)
                                    .bold()
                                Text("serving")
                                    .font(.subheadline)
                                    .fontWeight(.light)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(storeEntry.costPerServingAmount(size: item.size).toString())
                                    .font(.subheadline)
                                    .bold()
                                Text(item.size.servingSizeAmount.unit.getAbbreviation().lowercased())
                                    .lineLimit(1)
                                    .font(.subheadline)
                                    .fontWeight(.light)
                            }
                            Spacer()
                            if let costPerEnergy = storeEntry.costPerEnergy(foodItem: item) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(costPerEnergy.toString())
                                        .font(.subheadline)
                                        .bold()
                                    Text("100 Cal")
                                        .font(.subheadline)
                                        .fontWeight(.light)
                                }
                            }
                            if item.size.totalAmount.unit.isWeight() {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(storeEntry.costPerWeight(size: item.size).toString())
                                        .font(.subheadline)
                                        .bold()
                                    Text("100 g")
                                        .font(.subheadline)
                                        .fontWeight(.light)
                                }
                            } else if item.size.totalAmount.unit.isVolume() {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(storeEntry.costPerVolume(size: item.size).toString())
                                        .font(.subheadline)
                                        .bold()
                                    Text("100 mL")
                                        .font(.subheadline)
                                        .fontWeight(.light)
                                }
                            }
                        }
                    }
                }
                .contextMenu {
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu("Sort") {
                        ForEach(SortType.allCases) { s in
                            Button(s.getName()) {
                                sortType = s
                            }.disabled(sortType == s)
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        switch sortDirection {
                        case .Ascending:
                            sortDirection = .Descending
                        case .Descending:
                            sortDirection = .Ascending
                        }
                    } label: {
                        Image(systemName: sortDirection.getIcon())
                    }
                }
            }
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
    
    private func findBestStoreEntry(_ item: FoodItem) -> FoodItem.StoreEntry? {
        item.storeEntries.sorted(by: { $0.costPerServingAmount(size: item.size) < $1.costPerServingAmount(size: item.size) }).first
    }
}

#Preview {
    let container = createTestModelContainer()
    createTestFoodItem(container.mainContext)
    return FoodDatabaseView()
        .modelContainer(container)
}
