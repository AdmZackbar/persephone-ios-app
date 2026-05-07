//
//  LogEntryEditView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/22/25.
//

import SwiftData
import SwiftUI

struct LogEntryEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var recentEntries: [FoodLogEntry]
    
    @State private var item: LogEntryItem
    @State private var sheetType: SheetType?
    
    let meals: [String] = ["Breakfast", "Brunch", "Lunch", "Dinner", "Snacks"]
    
    init(item: LogEntryItem = .init()) {
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
                ForEach(meals, id: \.hashValue) { meal in
                    Text(meal).tag(meal)
                }
            }
            switch item.type {
            case .food:
                foodSection()
            case .recipe:
                recipeSection()
            case .meal:
                mealSection()
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
                    item.amount = newValue.servingSize.value
                }
            }
            .onChange(of: item.recipe) { oldValue, newValue in
                if let newValue {
                    item.amount = newValue.total.value / newValue.totalNumServings
                }
            }
            .sheet(item: $sheetType) { type in
                switch type {
                case .food:
                    SelectFoodSheet(selection: $item.food, suggestedFoods: recentEntries.map({ $0.food }).uniqued().prefix(24).map({ $0! }))
                case .recipe:
                    SelectRecipeEntrySheet(selection: $item.recipe)
                case .meal:
                    SelectMealSheet(selection: $item.mealEntry)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $item.type) {
                        ForEach(LogEntryItem.LogEntryType.allCases, id: \.hashValue) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }.pickerStyle(.segmented)
                        .frame(width: 160)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(item.isEdit ? "Save" : "Add") {
                        item.save(modelContext)
                        dismiss()
                    }.disabled(item.isInvalid)
                }
            }
    }
    
    @ViewBuilder
    private func foodSection() -> some View {
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
                if let size = item.size {
                    ScaledFoodView(food: food, size: size, servingCost: item.servingCost, numServings: item.numServings)
                }
            }
            Button {
                sheetType = .food
            } label: {
                Label(item.food != nil ? "Change Food" : "Select Food", systemImage: "fork.knife.circle")
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
                        Button(amount.formatted(maxDigits: 1)) {
                            Task {
                                item.amount.unitStr = amount.unitStr
                                // TODO horrible hack to fix switch bug
                                try await Task.sleep(nanoseconds: 50_000_000)
                                item.amount.value = amount.value
                            }
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
    
    @ViewBuilder
    private func recipeSection() -> some View {
        Section("Recipe") {
            if let recipe = item.recipe {
                let units: [Amount.Unit] = {
                    let servingUnit = Amount.Unit(name: "Serving", abbreviation: recipe.total.amount.unit?.abbreviation ?? "serving", modifier: recipe.total.val / recipe.total.amount.value.raw)
                    if recipe.total.isMass {
                        return [servingUnit, Units.gram, Units.ounce, Units.pound]
                    } else {
                        return [servingUnit, Units.milliliter, Units.fluidounce]
                    }
                }()
                ScaledAmountField(amount: $item.amount, units: units)
                otherAmountView(recipe)
                recipeView(recipe)
            }
            Button {
                sheetType = .recipe
            } label: {
                Label(item.food != nil ? "Change Recipe" : "Select Recipe", systemImage: "fork.knife.circle")
            }
        }
    }
    
    @ViewBuilder
    private func recipeView(_ recipe: RecipeEntry) -> some View {
        let scale = item.numServings
        HStack {
            VStack(alignment: .leading) {
                Text(recipe.name)
                    .font(.headline)
                Text((recipe.total * scale).formatted())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if let totalCost = recipe.cost {
                    Text((totalCost * scale).formatted())
                        .font(.subheadline)
                        .italic()
                }
                Gauge(value: item.remainingScale ?? 1, in: 0...1) {
                    EmptyView()
                }
                Spacer()
            }.padding(.top, 8)
            Spacer()
            NutrientPieChart(nutrients: recipe.nutrients * scale)
                .frame(width: 120, height: 120)
        }
    }
    
    @ViewBuilder
    private func mealSection() -> some View {
        Section("Meal") {
            if let meal = item.mealEntry {
                Text(meal.name)
            }
            // TODO
//            if let meal = item.mealEntry {
//                let units: [Amount.Unit] = {
//                    let servingUnit = Amount.Unit(name: "Serving", abbreviation: recipe.total.amount.unit?.abbreviation ?? "serving", modifier: recipe.total.val / recipe.total.amount.value.raw)
//                    if recipe.total.isMass {
//                        return [servingUnit, Units.gram, Units.ounce, Units.pound]
//                    } else {
//                        return [servingUnit, Units.milliliter, Units.fluidounce]
//                    }
//                }()
//                ScaledAmountField(amount: $item.amount, units: units)
//                otherAmountView(recipe)
//                recipeView(recipe)
//            }
            Button {
                sheetType = .meal
            } label: {
                Label(item.food != nil ? "Change Meal" : "Select Meal", systemImage: "fork.knife")
            }
        }
    }
    
    @ViewBuilder
    private func otherAmountView(_ recipe: RecipeEntry) -> some View {
        let amounts = (recipe.logEntries ?? []).sorted(by: { $0.date > $1.date }).map({ $0.amount }).uniqued()
        if !amounts.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(amounts, id: \.hashValue) { amount in
                        Button(amount.formatted(maxDigits: 1, includeSpace: true)) {
                            Task {
                                item.amount.unitStr = amount.unitStr
                                // TODO horrible hack to fix switch bug
                                try await Task.sleep(nanoseconds: 50_000_000)
                                item.amount.value = amount.value
                            }
                        }
                    }
                }
            }
        }
    }
}

private enum SheetType: String, Identifiable {
    var id: String {
        rawValue
    }
    
    case food
    case recipe
    case meal
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
                Text(size.formatted())
                    .font(.subheadline)
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
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        LogEntryEditView(item: .init(meal: "Breakfast"))
            .handleDestinations(navigationStore)
    }.environmentObject(navigationStore)
}
