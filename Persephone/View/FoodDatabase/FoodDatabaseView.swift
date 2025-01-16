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
                .init("Buns"),
                .init("Rolls")
            ]),
            .init("Cereal"),
            .init("Chips"),
            .init("Crackers"),
            .init("Fries"),
            .init("Hash Browns"),
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
            .init("Sandwich"),
            .init("Pizza")
        ]),
        .init("Meat", children: [
            .init("Bacon"),
            .init("Beef"),
            .init("Chicken"),
            .init("Fake Meat"),
            .init("Ham"),
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
            .init("Cake"),
            .init("Chocolate"),
            .init("Cookies"),
            .init("Cupcake"),
            .init("Ice Cream"),
            .init("Honey"),
            .init("Milkshake"),
            .init("Muffin"),
            .init("Pastry"),
            .init("Sugar")
        ]),
        .init("Vegetable", children: [
            .init("Broccoli"),
            .init("Green Beans"),
            .init("Onion"),
        ])
    ]
    
    @StateObject private var navigationStore = NavigationStore()
    @State private var showDeleteDialog = false
    @State private var selectedItem: FoodItem? = nil
    
    var body: some View {
        return NavigationStack(path: $navigationStore.path) {
            List {
                OutlineGroup(FoodDatabaseView.MainFoodTypes, id: \.name, children: \.children) { type in
                    Button {
                        navigationStore.push(ViewType.ItemsView(type: type))
                    } label: {
                        HStack {
                            Text(type.name)
                            Spacer()
                        }.contentShape(Rectangle())
                    }.buttonStyle(.plain)
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
            .handleDestinations(navigationStore)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            navigationStore.push(ViewType.ScanItem)
                        } label: {
                            Label("Scan Food", systemImage: "barcode.viewfinder")
                        }
                        Button {
                            navigationStore.push(ViewType.LookupItem)
                        } label: {
                            Label("Lookup Food", systemImage: "magnifyingglass")
                        }
                        Button {
                            navigationStore.push(ViewType.ItemAdd)
                        } label: {
                            Label("Add Custom Food Item", systemImage: "plus")
                        }
                        Button {
                            navigationStore.push(ViewType.CommercialFoodAdd)
                        } label: {
                            Label("Add Commercial Food", systemImage: "plus")
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        navigationStore.push(ViewType.ExportItems(items: foodItems))
                    } label: {
                        Label("Export Database", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }.environmentObject(navigationStore)
    }
    
    private func editLink(item: FoodItem) -> some View {
        Button {
            navigationStore.push(ViewType.ItemEdit(item: item))
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
}

struct ItemsView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \FoodItem.name) var foodItems: [FoodItem]
    @Query(sort: \CommercialFood.name) var commercialFood: [CommercialFood]
    @EnvironmentObject var navigationStore: NavigationStore
    
    let foodType: FoodDatabaseView.FoodType
    
    @State private var search: String = ""
    @State private var sortType: SortType = .Name
    @State private var sortDirection: SortDirection = .Ascending
    @State private var viewType: ViewType = .Cost
    
    init(foodType: FoodDatabaseView.FoodType) {
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
        items = items.sorted { a, b in
            switch (sortDirection) {
            case .Ascending:
                switch (sortType) {
                case .Brand:
                    return a.getName() < b.getName()
                case .DateAdded:
                    return a.getTimestamp() < b.getTimestamp()
                case .Name:
                    return a.getName() < b.getName()
                }
            case .Descending:
                switch (sortType) {
                case .Brand:
                    return a.getName() > b.getName()
                case .DateAdded:
                    return a.getTimestamp() > b.getTimestamp()
                case .Name:
                    return a.getName() > b.getName()
                }
            }
        }
        return List(items) { item in
            switch item {
            case .regular(let food):
                Button {
                    navigationStore.push(FoodDatabaseView.ViewType.ItemView(item: food))
                } label: {
                    itemView(food)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button {
                                navigationStore.push(FoodDatabaseView.ViewType.ItemEdit(item: food))
                            } label: {
                                Label("Edit", systemImage: "pencil.circle")
                            }
                            Menu("Set Tier") {
                                ForEach(RatingTier.allCases, id: \.rawValue) { tier in
                                    Button(tier.rawValue) {
                                        food.metaData.rating = tier.rating
                                    }.disabled(RatingTier.fromRating(rating: food.metaData.rating) == tier)
                                }
                                if RatingTier.fromRating(rating: food.metaData.rating) != nil {
                                    Button("Clear") {
                                        food.metaData.rating = nil
                                    }
                                }
                            }
                            Button(role: .destructive) {
                                modelContext.delete(food)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } preview: {
                            FoodItemPreview(item: food)
                        }
                }.buttonStyle(.plain)
            case .commercial(let food):
                Button {
                    navigationStore.push(FoodDatabaseView.ViewType.CommercialFoodView(food: food))
                } label: {
                    foodView(food)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button {
                                navigationStore.push(FoodDatabaseView.ViewType.CommercialFoodEdit(food: food))
                            } label: {
                                Label("Edit", systemImage: "pencil.circle")
                            }
                            Menu("Set Tier") {
                                ForEach(RatingTier.allCases, id: \.rawValue) { tier in
                                    Button(tier.rawValue) {
                                        food.metaData.rating = tier.rating
                                    }.disabled(RatingTier.fromRating(rating: food.metaData.rating) == tier)
                                }
                                if RatingTier.fromRating(rating: food.metaData.rating) != nil {
                                    Button("Clear") {
                                        food.metaData.rating = nil
                                    }
                                }
                            }
                            Button(role: .destructive) {
                                modelContext.delete(food)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } preview: {
                            CommercialFoodPreview(food: food)
                        }
                }.buttonStyle(.plain)
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
                       let tier = RatingTier.fromRating(rating: rating) {
                        Text("\(tier.rawValue) Tier")
                            .font(.subheadline)
                            .bold()
                    }
                }
                Spacer()
                NutrientPieChart(nutrients: item.ingredients.nutrients)
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
                           let tier = RatingTier.fromRating(rating: rating) {
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
                       let tier = RatingTier.fromRating(rating: rating) {
                        Text("\(tier.rawValue) Tier")
                            .font(.subheadline)
                            .bold()
                    }
                }
                Spacer()
                NutrientPieChart(nutrients: food.nutrients)
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
                           let tier = RatingTier.fromRating(rating: rating) {
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
                Text(item.size.servingSizeAmount.unit.abbreviation.lowercased())
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
            if item.size.totalAmount.unit.isWeight {
                VStack(alignment: .leading, spacing: 2) {
                    Text(storeEntry.costPerWeight(size: item.size).toString())
                        .font(.subheadline)
                        .bold()
                    Text("100 g")
                        .font(.subheadline)
                        .fontWeight(.light)
                }
            } else if item.size.totalAmount.unit.isVolume {
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
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    FoodDatabaseView()
}
