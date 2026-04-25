//
//  MealItemSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 4/24/26.
//

import SwiftData
import SwiftUI

struct MealItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Binding var meal: MealEditItem
    @State var item: MealItemEditItem
    @State private var filter: String = ""
    @State private var searchPresented: Bool = true
    
    init(meal: Binding<MealEditItem>, item: MealItemEditItem = .init()) {
        self._meal = meal
        self.item = item
    }
    
    var body: some View {
        NavigationStack {
            mainView()
                .navigationTitle(item.isEdit ? "Edit Food Entry" : "Add Food Entry")
                .navigationBarTitleDisplayMode(.inline)
                .onChange(of: item.food) { oldValue, newValue in
                    if let newValue {
                        if let storeEntry = newValue.bestStoreEntry {
                            item.servingCost = storeEntry.cost / storeEntry.numServings(newValue.servingSize)
                        } else {
                            item.servingCost = nil
                        }
                        item.defaultAmount = newValue.servingSize.amount
                    }
                }
                .toolbar(content: toolbarContent)
        }
    }
    
    @ViewBuilder
    private func mainView() -> some View {
        if let food = item.food {
            Form {
                amountView(food)
            }
        } else {
            SelectFoodView(selection: $item.food, filter: $filter)
                .searchable(text: $filter, isPresented: $searchPresented)
        }
    }
    
    @ViewBuilder
    private func amountView(_ food: Food) -> some View {
        let numServings: Double = {
            if let modifier = item.defaultAmount.unit?.modifier {
                return (item.defaultAmount.value.raw * modifier) / food.servingSize.val
            }
            return item.defaultAmount.value.raw
        }()
        let units: [Amount.Unit] = {
            let servingUnit = Amount.Unit(name: "Serving", abbreviation: food.servingSize.amount.unit?.abbreviation ?? "serving", modifier: food.servingSize.val / food.servingSize.amount.value.raw)
            if food.servingSize.isMass {
                return [servingUnit, Units.gram, Units.ounce, Units.pound]
            } else {
                return [servingUnit, Units.milliliter, Units.fluidounce]
            }
        }()
        ScaledAmountField(amount: $item.defaultAmount, units: units)
        costView(food)
        ScaledFoodView(food: food, size: food.servingSize * numServings, servingCost: item.servingCost, numServings: numServings)
        Button {
            item.food = nil
        } label: {
            Label("Change Food", systemImage: "pencil")
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
                        Button("\(storeEntry.store)\(storeEntry.isSale ? " (Sale)" : ""):\n\(storeEntry.amount.formatted()) \(servingCost.formatted())") {
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
                if let ingredient = item.save() {
                    meal.items.append(ingredient)
                }
                dismiss()
            }.disabled(item.isInvalid)
        }
    }
}

private struct SelectFoodView: View {
    @Query(filter: #Predicate { $0.metaData.retireDate == nil },
           sort: \Food.name) var foods: [Food]
    
    let suggestedFoods: [Food]
    
    var isFiltered: Bool {
        filter.count > 1
    }
    
    @Binding private var selection: Food?
    @Binding private var filter: String
    
    init(selection: Binding<Food?>, filter: Binding<String>, suggestedFoods: [Food] = []) {
        self._selection = selection
        self._filter = filter
        self.suggestedFoods = suggestedFoods
    }
    
    var body: some View {
        Form {
            let f: [Food] = {
                if isFiltered {
                    return foods.filter({ $0.contains(filter) })
                }
                return suggestedFoods
            }()
            if f.isEmpty {
                let reason = {
                    if foods.isEmpty {
                        "No Foods in DB"
                    } else if isFiltered {
                        "No Foods Matching \(filter)"
                    } else {
                        "No Suggested Foods"
                    }
                }()
                Text(reason)
            } else {
                if isFiltered {
                    foodsView(f)
                } else {
                    Section("Recent Foods") {
                        foodsView(f)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func foodsView(_ foods: [Food]) -> some View {
        ForEach(foods, id: \.hashValue) { food in
            Button {
                selection = food
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        if let brand = food.brand {
                            Text(brand)
                                .font(.caption)
                                .italic()
                        }
                        Text(food.name)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @State var meal: MealEditItem = .init()
    MealItemSheet(meal: $meal)
}
