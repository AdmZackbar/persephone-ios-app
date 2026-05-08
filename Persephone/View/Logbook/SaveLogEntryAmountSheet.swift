//
//  SaveLogEntryAmountSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/7/26.
//

import SwiftData
import SwiftUI

/// An editor for a LogEntryItem. Should be used in a sheet.
struct SaveLogEntryAmountSheet: View {
    /// Used to dismiss the sheet
    @Environment(\.dismiss) private var dismiss
    /// Used to save the item to the DB
    @Environment(\.modelContext) private var modelContext
    
    /// Contains recent log entries relating to the food of the item
    @Query private var recentFoodEntries: [FoodLogEntry]
    
    /// Contains the current state of the item
    @State var item: LogEntryItem
    
    /**
     Creates a new sheet that has its initial value set to the given item.
     The given item is not directly updated, but is instead updated through a model context
     if the user decides to save.
     
     - Parameter item: the initial item to base edits on
     - Returns: the created view for the item
     */
    init(item: LogEntryItem) {
        self.item = item
        if let foodId = item.food?.id {
            // Get all entries with the same food, sorted by most recent
            _recentFoodEntries = Query(filter: #Predicate<FoodLogEntry> { entry in
                entry.food?.id == foodId
            }, sort: \.date, order: .reverse)
        } else {
            // Set to empty
            _recentFoodEntries = Query(filter: #Predicate<FoodLogEntry> { _ in false })
        }
    }
    
    /// Builds the list of appropriate units to display as options
    private func computeUnits() -> [Amount.Unit] {
        if let food = item.food {
            let servingUnit = Amount.Unit(name: "Serving", abbreviation: food.servingSize.amount.unit?.abbreviation ?? "serving", modifier: food.servingSize.val / food.servingSize.amount.value.raw)
            if food.servingSize.isMass {
                return [servingUnit, .gram]
            } else {
                return [servingUnit, .milliliter]
            }
        } else if let recipe = item.recipe {
            let servingUnit = Amount.Unit(name: "Serving", abbreviation: recipe.total.amount.unit?.abbreviation ?? "serving", modifier: recipe.total.val / recipe.total.amount.value.raw)
            if recipe.total.isMass {
                return [servingUnit, .gram]
            } else {
                return [servingUnit, .milliliter]
            }
        } else {
            return [.gram]
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ScaledAmountField(amount: $item.amount, units: computeUnits())
                } header: {
                    if let food = item.food {
                        foodSummaryView(food)
                    } else if let recipe = item.recipe {
                        recipeSummaryView(recipe)
                    }
                } footer: {
                    if !recentFoodEntries.isEmpty {
                        recentEntriesView()
                    }
                }
                if let food = item.food {
                    priceView(food)
                }
            }.listSectionSpacing(.compact)
                .toolbar(content: toolbarContent)
                .toolbarTitleDisplayMode(.inline)
                .presentationDetents([.height(420)])
                // Don't use liquid glass as main background
                .presentationBackground(.regularMaterial)
        }
    }
    
    /// Displays a small multiline summary view for the given food
    @ViewBuilder
    private func foodSummaryView(_ food: Food) -> some View {
        let nutrients = food.ingredients.nutrients * item.numServings
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    if let brand = food.brand {
                        Text(brand)
                            .font(.subheadline)
                            .italic()
                    }
                    Text(food.name)
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    if let cost = item.servingCost {
                        Text((cost * item.numServings).formatted())
                            .font(.subheadline)
                            .italic()
                    }
                    Text(nutrients.calories.formatted())
                        .fontWeight(.bold)
                }
            }
            MacroBarChart(nutrients: nutrients, textFormat: .gram, textLayout: .center)
                .frame(height: 14)
                .font(.caption2)
        }.foregroundStyle(.primary)
    }
    
    /// Displays a small multiline summary view for the given recipe
    @ViewBuilder
    private func recipeSummaryView(_ recipe: RecipeEntry) -> some View {
        let nutrients = recipe.nutrients * item.numServings
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text(recipe.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .italic()
                    Text(recipe.name)
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    if let cost = item.servingCost {
                        Text((cost * item.numServings).formatted())
                            .font(.subheadline)
                            .italic()
                    }
                    Text(nutrients.calories.formatted())
                        .fontWeight(.bold)
                }
            }
            MacroBarChart(nutrients: nutrients, textFormat: .gram, textLayout: .center)
                .frame(height: 14)
                .font(.caption2)
        }.foregroundStyle(.primary)
    }
    
    /// Scrolling list of options that contain recent 'amounts' in other log entries
    private func recentEntriesView() -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(recentFoodEntries.map({ $0.amount }).uniqued().prefix(10), id: \.hashValue) { amount in
                    Button {
                        Task {
                            item.amount.unitStr = amount.unitStr
                            // TODO horrible hack to fix switch bug
                            try await Task.sleep(nanoseconds: 50_000_000)
                            item.amount.value = amount.value
                        }
                    } label: {
                        Text(amount.formatted(maxDigits: 1, includeSpace: true))
                            .bold()
                    }.buttonStyle(.glass)
                }
            }
        }.scrollIndicators(.hidden)
            .scrollClipDisabled()
            // Line up with form sections
            .padding([.leading, .trailing], -14)
    }
    
    /// Section with a currency editor and potential buttons to set the price from previous entries
    @ViewBuilder
    private func priceView(_ food: Food) -> some View {
        Section {
            VStack {
                HStack {
                    if let unwrappedValue = Binding($item.servingCost) {
                        CurrencyField(value: unwrappedValue)
                    } else {
                        Text((item.servingCost ?? .zero).formatted())
                    }
                    Spacer()
                    Text("$ per \(food.servingSize.formatted())")
                }
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(food.storeEntries.filter({ $0.isAvailable }), id: \.hashValue) { storeEntry in
                            Button {
                                item.servingCost = storeEntry.costPerServing(food.servingSize)
                            } label: {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(storeEntry.store)
                                            .italic()
                                        Text(storeEntry.cost.formatted())
                                            .font(.subheadline)
                                            .bold()
                                    }
                                    Text(storeEntry.amount.formatted())
                                        .font(.caption)
                                }
                            }.buttonStyle(.glass)
                        }
                    }
                }.scrollIndicators(.hidden)
                    .scrollClipDisabled()
            }
        }
    }
    
    /// Contains all the tool bar items for the main view
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            DatePicker(selection: $item.date, displayedComponents: [.hourAndMinute]) {
                EmptyView()
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            // Picker sucks in the toolbar, use menu instead
            Menu {
                ForEach(MealType.allCases.reversed()) { mealType in
                    Button {
                        item.meal = mealType.rawValue
                    } label: {
                        Label(mealType.rawValue, systemImage: mealType.getIconName())
                    }.disabled(item.meal == mealType.rawValue)
                }
            } label: {
                Text(item.meal)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                item.save(modelContext)
                dismiss()
            } label: {
                if item.isEdit {
                    Label("Save", systemImage: "checkmark")
                } else {
                    Label("Add", systemImage: "plus")
                }
            }.disabled(item.isInvalid)
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    VStack {
        
    }.sheet(isPresented: .constant(true)) {
        SaveLogEntryAmountSheet(item: .init(meal: "Snacks"))
    }
}
