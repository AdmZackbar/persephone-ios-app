//
//  CookedFoodEditView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/15/25.
//

import SwiftData
import SwiftUI

struct CookedFoodEditView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var item: Item
    @State private var sheetType: SheetType? = nil
    
    init(item: Item) {
        self.item = item
    }
    
    var body: some View {
        Form {
            Section {
                DatePicker("Date:", selection: $item.date)
                TextField("Name", text: $item.name)
                if let recipe = item.recipe {
                    Button("Recipe: \(recipe.name)") {
                        sheetType = .recipe
                    }
                } else {
                    Button("Set Recipe:") {
                        sheetType = .recipe
                    }
                }
                TextField("Notes", text: $item.notes, axis: .vertical)
                    .lineLimit(3...12)
            }
            Section {
                ForEach(item.ingredients, id: \.hashValue) { ingredient in
                    Button {
                        sheetType = .ingredient(ingredient: ingredient)
                    } label: {
                        CookedFoodIngredientEntryView(ingredient)
                    }.buttonStyle(.plain)
                }.onDelete { indices in
                    for index in indices {
                        item.ingredients.remove(at: index)
                    }
                }
            } header: {
                HStack {
                    Text("Ingredients")
                    Spacer()
                    Button {
                        sheetType = .ingredient()
                    } label: {
                        Label("Add", systemImage: "plus").labelStyle(.iconOnly)
                    }
                }
            }.headerProminence(.increased)
            sizeSection()
            Section {
                NutrientTableView(nutrients: item.ingredients.totalNutrition + item.adjustNutrition)
            } header: {
                HStack {
                    Text("Nutrition")
                    Spacer()
                    Button {
                        sheetType = .nutrition
                    } label: {
                        Label("Edit", systemImage: "pencil").labelStyle(.iconOnly)
                    }
                }
            }.headerProminence(.increased)
        }.navigationTitle(item.editMode ? "Edit Entry" : "Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        item.save(modelContext)
                        dismiss()
                    }
                }
            }
            .sheet(item: $sheetType) { type in
                switch type {
                case .ingredient(let ingredient):
                    if let ingredient {
                        EditIngredientSheet(item: .init(cookedFoodItem: $item, ingredient: ingredient))
                    } else {
                        EditIngredientSheet(item: .init(cookedFoodItem: $item))
                    }
                case .nutrition:
                    NutrientSheet(nutrients: $item.adjustNutrition)
                case .recipe:
                    SelectRecipeSheet(item: $item)
                }
            }
    }
    
    @ViewBuilder
    private func sizeSection() -> some View {
        let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            formatter.zeroSymbol = ""
            formatter.groupingSeparator = ""
            return formatter
        }()
        Section {
            HStack {
                Text("Total Weight:")
                TextField("g", value: $item.total, formatter: formatter)
                    .keyboardType(.numberPad)
                if item.total > 0 {
                    Text("g")
                }
            }
            HStack {
                Text("Remaining Weight:")
                TextField("g", value: $item.remaining, formatter: formatter)
                    .keyboardType(.numberPad)
                if item.total > 0 {
                    Text("g")
                }
            }
            HStack {
                Text("Num Servings:").fontWeight(.light)
                TextField("required", value: $item.numServings, formatter: formatter)
                    .keyboardType(.decimalPad)
            }
            HStack {
                Text("Serving Size:").fontWeight(.light)
                if item.numServings > 0 {
                    HStack {
                        TextField("required", text: $item.servingSize)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                        Spacer()
                        Text("(\(formatter.string(for: item.total / item.numServings)!)g)")
                            .fontWeight(.light)
                            .italic()
                    }
                } else {
                    TextField("required", text: $item.servingSize)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
            }
        }
    }
    
    private enum SheetType: Identifiable {
        var id: String {
            switch self {
            case .ingredient(_):
                return "Ingredient"
            case .nutrition:
                return "Nutrition"
            case .recipe:
                return "Recipe"
            }
        }
        
        case ingredient(ingredient: CookedFoodIngredient? = nil)
        case nutrition
        case recipe
    }
    
    struct Item {
        private var cookedFood: CookedFood?
        var editMode: Bool {
            cookedFood != nil
        }
        
        var date: Date
        var name: String
        var recipe: Recipe?
        var notes: String
        var total: Double
        var remaining: Double
        var adjustNutrition: NutritionDict
        var ingredients: [CookedFoodIngredient]
        var numServings: Double
        var servingSize: String
        
        var totalNutrition: NutritionDict {
            ingredients.map({ $0.foodItem.ingredients.nutrients }).reduce(adjustNutrition, +)
        }
        
        init(cookedFood: CookedFood) {
            self.cookedFood = cookedFood
            self.date = cookedFood.date
            self.name = cookedFood.name
            self.recipe = cookedFood.recipe
            self.notes = cookedFood.notes
            self.total = cookedFood.total
            self.remaining = cookedFood.remaining
            self.adjustNutrition = cookedFood.adjustNutrition
            self.ingredients = cookedFood.ingredients
            self.numServings = cookedFood.size.numServings
            self.servingSize = cookedFood.size.servingSize
        }
        
        init() {
            self.date = Date()
            self.name = ""
            self.recipe = nil
            self.notes = ""
            self.total = 0
            self.remaining = 0
            self.adjustNutrition = [:]
            self.ingredients = []
            self.numServings = 1
            self.servingSize = ""
        }
        
        mutating func save(_ modelContext: ModelContext) {
            if let cookedFood {
                cookedFood.date = date
                cookedFood.name = name
                cookedFood.recipe = recipe
                cookedFood.notes = notes
                cookedFood.total = total
                cookedFood.remaining = remaining
                cookedFood.adjustNutrition = adjustNutrition
                cookedFood.ingredients = ingredients
                cookedFood.size = .init(totalAmount: .grams(total), numServings: numServings, servingSize: servingSize)
            } else {
                cookedFood = .init(date: date, name: name, recipe: recipe, ingredients: ingredients, notes: notes, total: total, remaining: remaining, adjustNutrition: adjustNutrition, size: .init(totalAmount: .grams(total), numServings: numServings, servingSize: servingSize))
                modelContext.insert(cookedFood!)
            }
        }
    }
    
    struct EditIngredientSheet: View {
        @Query(sort: \FoodItem.name) var foodItems: [FoodItem]
        @Environment(\.dismiss) var dismiss
        @Environment(\.modelContext) var modelContext
        
        @State private var item: Item
        @State private var filter: String = ""
        
        init(item: Item) {
            self.item = item
        }
        
        var body: some View {
            NavigationStack {
                Form {
                    if let foodItem = item.foodItem {
                        foodAmountView(foodItem)
                    } else {
                        selectFoodView()
                    }
                }.navigationTitle(item.editMode ? "Edit Ingredient" : "Add Ingredient")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            Button("Save") {
                                item.save()
                                dismiss()
                            }.disabled(item.foodItem == nil)
                        }
                    }
            }.presentationDetents([.medium])
        }
        
        @ViewBuilder
        private func foodAmountView(_ foodItem: FoodItem) -> some View {
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
                        (item.amount * foodItem.size.servingSizeAmount.value.value).toString()
                    } else {
                        (item.amount * foodItem.size.servingAmount.value.value).toString()
                    }
                }, set: { str in
                    if let value = Quantity.Magnitude.parseString(str) {
                        if item.amountUnit == nil {
                            item.amount = value / foodItem.size.servingSizeAmount.value.value
                        } else {
                            item.amount = value / foodItem.size.servingAmount.value.value
                        }
                    }
                })).keyboardType(.decimalPad)
                    .font(.title)
                    .bold()
            }
//                    similarEntryView(foodItem)
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
        
//        @ViewBuilder
//        private func similarEntryView(_ foodItem: FoodItem) -> some View {
//            let similarEntries: [SimilarEntry] = {
//                let entries = entries.filter({ $0.item == foodItem })
//                var similarEntries: [SimilarEntry] = []
//                for entry in entries {
//                    if !similarEntries.contains(where: { $0.amount == entry.amount }) {
//                        similarEntries.append(.init(amount: entry.amount, unit: entry.amountUnit))
//                    }
//                    if similarEntries.count >= 8 {
//                        break
//                    }
//                }
//                return similarEntries
//            }()
//            if !similarEntries.isEmpty {
//                ScrollView(.horizontal) {
//                    HStack(spacing: 10) {
//                        ForEach(similarEntries, id: \.hashValue) { similarEntry in
//                            Button {
//                                item.amount = similarEntry.amount
//                                item.amountUnit = similarEntry.unit
//                            } label: {
//                                switch similarEntry.unit {
//                                case .none:
//                                    Text("\((similarEntry.amount * foodItem.size.servingSizeAmount.value.value).toString(maxDigits: 1)) \(foodItem.size.servingSizeAmount.unit.abbreviation)")
//                                default:
//                                    Text("\((similarEntry.amount * foodItem.size.servingAmount.value.value).toString())\(foodItem.size.servingAmount.unit.abbreviation)")
//                                }
//                                
//                            }
//                            Divider()
//                        }
//                    }
//                }
//            }
//        }
//        
//        private struct SimilarEntry: Hashable, Equatable {
//            var amount: Quantity.Magnitude
//            var unit: Unit?
//        }
        
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
            private var ingredient: CookedFoodIngredient?
            var editMode: Bool {
                ingredient != nil
            }
            
            @Binding
            private var cookedFoodItem: CookedFoodEditView.Item
            
            var foodItem: FoodItem?
            var amount: Quantity.Magnitude
            var amountUnit: Unit?
            var unitPrice: Price
            var hasPrice: Bool
            
            init(cookedFoodItem: Binding<CookedFoodEditView.Item>, ingredient: CookedFoodIngredient) {
                self.ingredient = ingredient
                self._cookedFoodItem = cookedFoodItem
                self.foodItem = ingredient.foodItem
                self.amount = ingredient.amount
                self.amountUnit = ingredient.amountUnit
                self.unitPrice = ingredient.unitPrice ?? .Cents(0)
                self.hasPrice = ingredient.unitPrice != nil
            }
            
            init(cookedFoodItem: Binding<CookedFoodEditView.Item>) {
                self.ingredient = nil
                self._cookedFoodItem = cookedFoodItem
                self.foodItem = nil
                self.amount = .Raw(1)
                self.amountUnit = nil
                self.unitPrice = .Cents(0)
                self.hasPrice = false
            }
            
            mutating func save() {
                if let ingredient {
                    ingredient.foodItem = foodItem
                    ingredient.amount = amount
                    ingredient.amountUnit = amountUnit
                    ingredient.unitPrice = hasPrice ? unitPrice : nil
                } else {
                    ingredient = .init(foodItem: foodItem!, amount: amount, amountUnit: amountUnit, unitPrice: hasPrice ? unitPrice : nil)
                    cookedFoodItem.ingredients.append(ingredient!)
                }
            }
        }
    }
}

struct CookedFoodIngredientEntryView: View {
    let ingredient: CookedFoodIngredient
    
    init(_ ingredient: CookedFoodIngredient) {
        self.ingredient = ingredient
    }
    
    var body: some View {
        let amount: String = {
            if ingredient.amountUnit == nil {
                "\((ingredient.amount * ingredient.foodItem.size.servingSizeAmount.value.value).toString()) \(ingredient.foodItem.size.servingSizeAmount.unit.abbreviation)"
            } else {
                "\((ingredient.amount * ingredient.foodItem.size.servingAmount.value.value).toString())\(ingredient.amountUnit!.abbreviation)"
            }
        }()
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Text(ingredient.foodItem.name)
                    .font(.headline)
                Spacer()
                Text(amount)
            }
            HStack(alignment: .top) {
                if let brand = ingredient.foodItem.metaData.brand {
                    Text(brand)
                }
                Spacer()
                if let cost = ingredient.price {
                    Text(cost.toString())
                        .italic()
                }
            }.font(.subheadline)
        }
    }
}

struct SelectRecipeSheet: View {
    @Environment(\.dismiss) var dismiss
    @Query(sort: \Recipe.name) var recipes: [Recipe]
    
    @Binding private var item: CookedFoodEditView.Item
    @State private var filter: String = ""
    
    init(item: Binding<CookedFoodEditView.Item>) {
        self._item = item
    }
    
    var body: some View {
        NavigationStack {
            Form {
                let recipes = recipes.filter({ filter.isEmpty || $0.name.localizedCaseInsensitiveContains(filter) })
                if recipes.isEmpty {
                    Text("No Recipes")
                } else {
                    ForEach(recipes, id: \.hashValue) { recipe in
                        Button {
                            item.recipe = recipe
                            dismiss()
                        } label: {
                            VStack(alignment: .leading) {
                                Text(recipe.name)
                                    .font(.headline)
                                if let author = recipe.metaData.author {
                                    Text(author)
                                        .font(.subheadline)
                                        .italic()
                                }
                            }
                        }
                    }
                }
            }.navigationTitle("Select Recipe")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Back") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Clear") {
                            item.recipe = nil
                            dismiss()
                        }.disabled(item.recipe == nil)
                    }
                }
        }.searchable(text: $filter)
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    NavigationStack {
        CookedFoodEditView(item: .init())
    }
}
