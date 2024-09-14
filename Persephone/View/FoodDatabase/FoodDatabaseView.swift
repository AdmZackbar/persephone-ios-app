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
        .init("Meal", children: [
            .init("Burger"),
            .init("Sandwich")
        ]),
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
        case CommercialFoodView(food: CommercialFood)
        case CommercialFoodAdd
        case CommercialFoodEdit(food: CommercialFood)
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
                            Label("Add Custom Food Item", systemImage: "plus")
                        }
                        Button {
                            path.append(.CommercialFoodAdd)
                        } label: {
                            Label("Add Commercial Food", systemImage: "plus")
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
        case .CommercialFoodView(let food):
            CommercialFoodView(path: $path, food: food)
        case .CommercialFoodAdd:
            CommercialFoodEditor()
        case .CommercialFoodEdit(let food):
            CommercialFoodEditor(food: food)
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
    @Query(sort: \CommercialFood.name) var commercialFood: [CommercialFood]
    
    enum Item: Identifiable {
        var id: Int {
            get {
                switch self {
                case .regular(let food):
                    food.id.hashValue
                case .commercial(let food):
                    food.id.hashValue
                }
            }
        }
        
        case regular(food: FoodItem)
        case commercial(food: CommercialFood)
        
        func getName() -> String {
            switch self {
            case .regular(let food):
                food.name
            case .commercial(let food):
                food.name
            }
        }
        
        func getBrand() -> String? {
            switch self {
            case .regular(let food):
                food.metaData.brand
            case .commercial(let food):
                food.seller
            }
        }
        
        func getTimestamp() -> Date {
            switch self {
            case .regular(let food):
                food.metaData.timestamp
            case .commercial(let food):
                food.metaData.timestamp
            }
        }
    }
    
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
    
    enum ViewType: Identifiable, CaseIterable {
        var id: String {
            get { getName() }
        }
        
        case Macro
        case Cost
        
        func getName() -> String {
            switch self {
            case .Macro:
                "Macros"
            case .Cost:
                "Cost"
            }
        }
    }
    
    let foodType: FoodDatabaseView.FoodType
    
    @Binding private var path: [FoodDatabaseView.ViewType]
    @State private var search: String = ""
    @State private var sortType: SortType = .Name
    @State private var sortDirection: SortDirection = .Ascending
    @State private var viewType: ViewType = .Cost
    
    init(path: Binding<[FoodDatabaseView.ViewType]>, foodType: FoodDatabaseView.FoodType) {
        self._path = path
        self.foodType = foodType
    }
    
    var body: some View {
        var items: [Item] = []
        items.append(contentsOf: (foodItems
            .filter({ foodType.containsTags($0.metaData.tags) && isSearchFiltered($0) })
            .map({ Item.regular(food: $0) })))
        items.append(contentsOf: (commercialFood
            .filter({ foodType.containsTags($0.metaData.tags) && isSearchFiltered($0) })
            .map({ Item.commercial(food: $0) })))
        return List(items) { item in
            switch item {
            case .regular(let food):
                NavigationLink(value: FoodDatabaseView.ViewType.ItemView(item: food)) {
                    itemView(food)
                        .contextMenu {
                            Button {
                                path.append(.ItemEdit(item: food))
                            } label: {
                                Label("Edit", systemImage: "pencil.circle")
                            }
                        } preview: {
                            FoodItemPreview(item: food)
                        }
                }
            case .commercial(let food):
                NavigationLink(value: FoodDatabaseView.ViewType.CommercialFoodView(food: food)) {
                    foodView(food)
                        .contextMenu {
                            Button {
                                path.append(.CommercialFoodEdit(food: food))
                            } label: {
                                Label("Edit", systemImage: "pencil.circle")
                            }
                        } preview: {
                            CommercialFoodPreview(food: food)
                        }
                }
            }
        }.navigationTitle(foodType.name)
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu("View") {
                        ForEach(ViewType.allCases) { v in
                            Button(v.getName()) {
                                viewType = v
                            }.disabled(viewType == v)
                        }
                    }
                }
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
    
    private func isSearchFiltered(_ item: CommercialFood) -> Bool {
        search.isEmpty || item.name.contains(search) || item.seller.contains(search)
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
    
    @ViewBuilder
    private func itemView(_ item: FoodItem) -> some View {
        switch viewType {
        case .Macro:
            HStack(alignment: .top, spacing: 2) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .bold()
                    Text(item.metaData.brand ?? "Generic")
                        .font(.subheadline)
                        .fontWeight(.light)
                        .italic()
                    if let rating = item.metaData.rating,
                       let tier = FoodTier.fromRating(rating: rating) {
                        Text("\(tier.rawValue) Tier")
                            .font(.subheadline)
                            .bold()
                    }
                }
                Spacer()
                MacroChartView(nutrients: item.ingredients.nutrients)
                    .frame(width: 140, height: 100)
            }
        case .Cost:
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
                    storeEntryView(item: item, storeEntry: storeEntry)
                }
            }
        }
    }
    
    @ViewBuilder
    private func foodView(_ food: CommercialFood) -> some View {
        switch viewType {
        case .Macro:
            HStack(alignment: .top, spacing: 2) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.headline)
                        .bold()
                    Text(food.seller)
                        .font(.subheadline)
                        .fontWeight(.light)
                        .italic()
                    Text(food.cost.toString())
                        .font(.subheadline)
                        .bold()
                    if let rating = food.metaData.rating,
                       let tier = FoodTier.fromRating(rating: rating) {
                        Text("\(tier.rawValue) Tier")
                            .font(.subheadline)
                            .bold()
                    }
                }
                Spacer()
                MacroChartView(nutrients: food.nutrients)
                    .frame(width: 140, height: 100)
            }
        case .Cost:
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(food.name)
                            .font(.headline)
                            .bold()
                        Spacer()
                        Text(food.cost.toString())
                            .font(.headline)
                            .bold()
                    }
                    HStack {
                        Text(food.seller)
                            .font(.subheadline)
                            .fontWeight(.light)
                            .italic()
                        Spacer()
                        if let rating = food.metaData.rating,
                           let tier = FoodTier.fromRating(rating: rating) {
                            Text("\(tier.rawValue) Tier")
                                .font(.subheadline)
                                .bold()
                        }
                    }
                }
            }
        }
    }
    
    private func storeEntryView(item: FoodItem, storeEntry: FoodItem.StoreEntry) -> some View {
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

#Preview {
    let container = createTestModelContainer()
    createTestFoodItem(container.mainContext)
    createTestCommercialFood(container.mainContext)
    return FoodDatabaseView()
        .modelContainer(container)
}
