//
//  FoodLogEntryEditView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/18/25.
//

import SwiftData
import SwiftUI

struct FoodLogEntryEditView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Query private var recentEntries: [FoodLogEntry]
    
    @State private var item: FoodLogEntryItem
    @State private var sheetType: SheetType? = nil
    
    init(item: FoodLogEntryItem = .init()) {
        self.item = item
        var descriptor = FetchDescriptor<FoodLogEntry>(
            sortBy: [
                .init(\.date, order: .reverse)
            ]
        )
        descriptor.fetchLimit = 100
        self._recentEntries = .init(descriptor)
    }
    
    var body: some View {
        Form {
            DatePicker("Date:", selection: $item.date)
            Picker("Meal:", selection: $item.meal) {
                ForEach(LogbookView.Meals, id: \.hashValue) { meal in
                    Text(meal).tag(meal)
                }
            }
            Section("Food") {
                if let food = item.food {
                    let units: [Amount.Unit] = {
                        let servingUnit = Amount.Unit(name: "Serving", abbreviation: food.servingSize.amount.unit?.abbreviation ?? "serving", modifier: food.servingSize.val / food.servingSize.amount.value.raw)
                        if food.servingSize.isMass {
                            return [servingUnit, Units.gram, Units.ounce, Units.pound]
                        } else {
                            return [servingUnit, Units.milliliter, Units.fluidounce]
                        }
                    }()
                    ScaledAmountField(amount: $item.amount, units: units)
                    latestAmountView(food)
                    costView(food)
                }
                Button {
                    sheetType = .food
                } label: {
                    foodView().contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
        }.navigationTitle(item.isEdit ? "Edit Entry" : "Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: item.food) { oldValue, newValue in
                if let newValue {
                    if let storeEntry = newValue.bestStoreEntry {
                        item.servingCost = storeEntry.cost / storeEntry.numServings(newValue.servingSize)
                    } else {
                        item.servingCost = nil
                    }
                    item.amount = newValue.servingSize.amount
                }
            }
            .sheet(item: $sheetType) { type in
                switch type {
                case .food:
                    SelectFoodSheet(selection: $item.food, suggestedFoods: recentEntries.map({ $0.food }).uniqued().prefix(24).map({ $0! }))
                }
            }
            .toolbar(content: toolbarContent)
    }
    
    @ViewBuilder
    private func foodView() -> some View {
        if let food = item.food {
            ScaledFoodView(food: food, size: item.size!, servingCost: item.servingCost, numServings: item.numServings)
        } else {
            HStack {
                Text("Select Food")
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func latestAmountView(_ food: Food) -> some View {
        let amounts = recentEntries.filter({ $0.food == food }).map({ $0.amount }).uniqued()
        if !amounts.isEmpty {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(amounts, id: \.hashValue) { amount in
                        Button(amount.formatted(maxDigits: 1, includeSpace: true)) {
                            // TODO fix bug with switching units
                            item.amount = amount
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func costView(_ food: Food) -> some View {
        let storeEntries = food.storeEntries.filter({ $0.isAvailable })
        HStack {
            if storeEntries.isEmpty {
                Text("Serving Cost:")
            } else {
                Menu {
                    ForEach(storeEntries, id: \.hashValue) { storeEntry in
                        let servingCost = storeEntry.costPerServing(food.servingSize)
                        Button("\(storeEntry.store)\(storeEntry.isSale ? " (Sale)" : ""):\n\(storeEntry.amount.formatted(maxDigits: 0)) \(servingCost.formatted())") {
                            item.servingCost = servingCost
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.down")
                        Text("Serving Cost:")
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
            OptionalCurrencyField(value: $item.servingCost)
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(item.isEdit ? "Save" : "Add") {
                item.save(modelContext)
                dismiss()
            }.disabled(item.isInvalid)
        }
    }
    
    private enum SheetType: String, Identifiable {
        var id: String {
            rawValue
        }
        
        case food
    }
}

struct ScaledFoodView: View {
    let food: Food
    let size: FoodSize
    let servingCost: Currency?
    let numServings: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if let brand = food.brand {
                    Text(brand)
                        .font(.subheadline)
                        .opacity(0.7)
                }
                Text(food.name)
                    .font(.headline)
                HStack(spacing: 4) {
                    Text(size.amount.formatted(includeSpace: true))
                    Text("(\(size.value.formatted()))")
                }.font(.subheadline)
                    .fontWeight(.semibold)
                if let servingCost {
                    Text((servingCost * numServings).formatted())
                        .font(.subheadline)
                        .italic()
                }
                Spacer()
            }.padding(.top, 8)
            Spacer()
            NutrientPieChart(nutrients: food.ingredients.nutrients * numServings)
                .frame(width: 120, height: 120)
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    NavigationStack {
        FoodLogEntryEditView(item: .init(meal: "Breakfast"))
    }
}
