//
//  FoodItemEntryEditView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/12/25.
//

import SwiftData
import SwiftUI

struct LogFoodItemEntryEditView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var navigationStore: NavigationStore
    @Query(sort: \FoodItem.name) var foodItems: [FoodItem]
    
    @State private var item: Item
    @State private var filter: String = ""
    
    init(item: Item) {
        self.item = item
    }
    
    init(category: String, type: LogType) {
        self.item = .init(category: category, type: type)
    }
    
    var body: some View {
        Form {
            Section("\(item.type)") {
                DatePicker("Date:", selection: $item.date, displayedComponents: .date)
                Picker("Meal:", selection: $item.category) {
                    ForEach(LogbookView.Categories, id: \.hashValue) { category in
                        Text(category).tag(category)
                    }
                }
            }
            if let foodItem = item.foodItem {
                foodAmountView(foodItem)
            } else {
                selectFoodView()
            }
        }.navigationTitle(item.entry != nil ? "Edit Entry" : "Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        item.save(modelContext)
                    }.disabled(item.foodItem == nil)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(item.entry != nil ? "Cancel" : "Back") {
                        navigationStore.pop()
                    }
                }
            }
    }
    
    @ViewBuilder
    private func foodAmountView(_ foodItem: FoodItem) -> some View {
        Section("Food") {
            TextField("Amount", text: Binding(get: {
                item.amount.toString()
            }, set: { str in
                if let value = Quantity.Magnitude.parseString(str) {
                    item.amount = value
                }
            })).autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            VStack(alignment: .leading) {
                HStack {
                    Text(foodItem.name)
                        .font(.headline)
                    Spacer()
                    Text("\((foodItem.size.servingSizeAmount.value * item.amount.value).toString()) \(foodItem.size.servingSizeAmount.unit.abbreviation)")
                        .bold()
                }
                HStack {
                    if let brand = foodItem.metaData.brand {
                        Text(brand)
                            .font(.subheadline)
                            .italic()
                    }
                    Spacer()
                    Text("\((foodItem.size.servingAmount.value * item.amount.value).toString())\(foodItem.size.servingAmount.unit.abbreviation)")
                        .font(.subheadline).bold()
                }
                NutrientPieChart(nutrients: foodItem.ingredients.nutrients * item.amount.value)
                    .frame(width: 160, height: 120)
            }
            Toggle(isOn: $item.hasPrice) {
                costEntryView(foodItem)
            }
        }
    }
    
    @ViewBuilder
    private func costEntryView(_ foodItem: FoodItem) -> some View {
        HStack {
            Text("Cost (\(foodItem.size.totalAmount.value.toString(maxDigits: 1))\(foodItem.size.totalAmount.unit.abbreviation)):")
            if item.hasPrice {
                CurrencyField(value: Binding(get: {
                    item.unitPrice.toCents()
                }, set: { value in
                    item.unitPrice = .Cents(value)
                }))
                if !foodItem.storeEntries.isEmpty {
                    Menu {
                        ForEach(foodItem.storeEntries, id: \.hashValue) { storeEntry in
                            Button("\(storeEntry.storeName)\(storeEntry.sale ? " (Sale)" : ""): \(storeEntry.costType.toString())") {
                                item.unitPrice = storeEntry.costPerUnit(size: foodItem.size)
                            }
                        }
                    } label: {
                        Label("Set", systemImage: "chevron.down").labelStyle(.iconOnly)
                    }
                }
            } else {
                Text("No Price Data")
            }
        }
    }
    
    @ViewBuilder
    private func selectFoodView() -> some View {
        Section("Food") {
            TextField("Search", text: $filter)
            if filter.count > 2 {
                let foodItems = foodItems.filter({ $0.contains(filter) })
                if !foodItems.isEmpty {
                    ForEach(foodItems, id: \.hashValue) { item in
                        Button(item.name) {
                            self.item.foodItem = item
                        }
                    }
                } else {
                    Text("No items found")
                }
            }
        }
    }
    
    struct Item {
        var entry: LogFoodItemEntry?
        
        var date: Date
        var foodItem: FoodItem?
        var amount: Quantity.Magnitude
        var category: String
        var type: LogType
        var hasPrice: Bool
        var unitPrice: Price
        
        init(entry: LogFoodItemEntry? = nil, category: String? = nil, type: LogType? = nil) {
            self.entry = entry
            self.date = entry?.date ?? .now
            self.foodItem = entry?.item
            self.amount = entry?.amount ?? .Raw(1)
            self.category = entry?.category ?? category ?? "Other"
            self.type = entry?.type ?? type ?? .actual
            self.hasPrice = entry?.unitPrice != nil
            self.unitPrice = entry?.unitPrice ?? .Cents(0)
        }
        
        mutating func save(_ modelContext: ModelContext) {
            if let entry {
                if let foodItem {
                    entry.date = date
                    entry.item = foodItem
                    entry.amount = amount
                    entry.category = category
                    entry.type = type
                    entry.unitPrice = hasPrice ? unitPrice : nil
                }
            } else if let foodItem {
                entry = .init(date: date,
                              item: foodItem,
                              amount: amount,
                              category: category,
                              type: type,
                              unitPrice: hasPrice ? unitPrice : nil)
                modelContext.insert(entry!)
            }
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        LogFoodItemEntryEditView(category: "Breakfast", type: .actual)
    }.environmentObject(navigationStore)
}
