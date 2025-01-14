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
        }.navigationTitle(item.isEditing ? "Edit Entry" : "Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        item.save(modelContext)
                        navigationStore.pop()
                    }.disabled(item.foodItem == nil)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(item.isEditing ? "Cancel" : "Back") {
                        navigationStore.pop()
                    }
                }
            }
    }
    
    @ViewBuilder
    private func foodAmountView(_ foodItem: FoodItem) -> some View {
        Section("Food") {
            Picker(selection: $item.amountUnit) {
                Text(foodItem.size.servingSizeAmount.unit.abbreviation).tag(nil as Unit?)
                if foodItem.size.totalAmount.unit.isWeight {
                    Text(Unit.Gram.abbreviation).tag(Unit.Gram)
                }
                if foodItem.size.totalAmount.unit.isVolume {
                    Text(Unit.Milliliter.abbreviation).tag(Unit.Milliliter)
                }
            } label: {
                TextField("Amount", text: Binding(get: {
                    if item.amountUnit == nil {
                        item.amount.toString()
                    } else {
                        (item.amount * foodItem.size.servingAmount.value.value).toString()
                    }
                }, set: { str in
                    if let value = Quantity.Magnitude.parseString(str) {
                        if item.amountUnit == nil {
                            item.amount = value
                        } else {
                            item.amount = value / foodItem.size.servingAmount.value.value
                        }
                    }
                })).keyboardType(.decimalPad)
            }
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(foodItem.name)
                            .font(.headline)
                        if let brand = foodItem.metaData.brand {
                            Text(brand)
                                .font(.subheadline)
                                .italic()
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\((foodItem.size.servingSizeAmount.value * item.amount.value).toString()) \(foodItem.size.servingSizeAmount.unit.abbreviation)")
                            .bold()
                        Text("\((foodItem.size.servingAmount.value * item.amount.value).toString())\(foodItem.size.servingAmount.unit.abbreviation)")
                            .font(.subheadline).bold()
                    }
                }
                NutrientPieChart(nutrients: foodItem.ingredients.nutrients * item.amount.value)
                    .frame(width: 160, height: 120)
            }
            Toggle(isOn: $item.hasPrice) {
                costEntryView(foodItem)
            }
            Button("Change Food") {
                filter = ""
                item.foodItem = nil
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
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if filter.count > 2 {
                let foodItems = foodItems.filter({ $0.contains(filter) })
                if !foodItems.isEmpty {
                    ForEach(foodItems, id: \.hashValue) { item in
                        Button(item.name) {
                            self.item.foodItem = item
                            self.item.amountUnit = {
                                if item.size.totalAmount.unit.isWeight {
                                    .Gram
                                } else if item.size.totalAmount.unit.isVolume {
                                    .Milliliter
                                } else {
                                    nil
                                }
                            }()
                            if let storeEntry = item.bestStoreEntry {
                                self.item.hasPrice = true
                                self.item.unitPrice = storeEntry.costPerUnit(size: item.size)
                            } else {
                                self.item.hasPrice = false
                            }
                        }
                    }
                } else {
                    Text("No items found")
                }
            }
        }
    }
    
    struct Item {
        private var entry: LogFoodItemEntry?
        var isEditing: Bool {
            entry != nil
        }
        
        var date: Date
        var foodItem: FoodItem? = nil
        var amount: Quantity.Magnitude
        var amountUnit: Unit?
        var category: String
        var type: LogType
        var hasPrice: Bool
        var unitPrice: Price
        
        init(entry: LogFoodItemEntry) {
            self.entry = entry
            self.date = entry.date
            self.foodItem = entry.item
            self.amount = entry.amount
            self.amountUnit = entry.amountUnit
            self.category = entry.category
            self.type = entry.type
            self.hasPrice = entry.unitPrice != nil
            self.unitPrice = entry.unitPrice ?? .Cents(0)
        }
        
        init(date: Date, category: String, type: LogType) {
            self.entry = nil
            self.date = date
            self.foodItem = nil
            self.amount = .Raw(1)
            self.amountUnit = nil
            self.category = category
            self.type = type
            self.hasPrice = false
            self.unitPrice = .Cents(0)
        }
        
        mutating func save(_ modelContext: ModelContext) {
            if let entry {
                if let foodItem {
                    entry.date = date
                    entry.item = foodItem
                    entry.amount = amount
                    entry.amountUnit = amountUnit
                    entry.category = category
                    entry.type = type
                    entry.unitPrice = hasPrice ? unitPrice : nil
                }
            } else if let foodItem {
                entry = .init(date: date,
                              item: foodItem,
                              amount: amount,
                              amountUnit: amountUnit,
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
        LogFoodItemEntryEditView(item: .init(date: .now, category: "Breakfast", type: .actual))
    }.environmentObject(navigationStore)
}
