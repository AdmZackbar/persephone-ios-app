//
//  SetAmountSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/7/26.
//

import SwiftData
import SwiftUI

struct SetAmountSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var recentFoodEntries: [FoodLogEntry]
    
    @State var item: LogEntryItem
    
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
    
    private func computeUnits() -> [Amount.Unit] {
        if let food = item.food {
            let servingUnit = Amount.Unit(name: "Serving", abbreviation: food.servingSize.amount.unit?.abbreviation ?? "serving", modifier: food.servingSize.val / food.servingSize.amount.value.raw)
            if food.servingSize.isMass {
                return [servingUnit, Units.gram]
            } else {
                return [servingUnit, Units.milliliter]
            }
        } else if let recipe = item.recipe {
            let servingUnit = Amount.Unit(name: "Serving", abbreviation: recipe.total.amount.unit?.abbreviation ?? "serving", modifier: recipe.total.val / recipe.total.amount.value.raw)
            if recipe.total.isMass {
                return [servingUnit, Units.gram]
            } else {
                return [servingUnit, Units.milliliter]
            }
        } else {
            return [Units.gram]
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
    
    @ViewBuilder
    private func foodSummaryView(_ food: Food) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .fontWeight(.semibold)
                HStack {
                    if let brand = food.brand {
                        Text(brand)
                    }
                }.font(.caption).italic()
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.amount.formatted())
                    .font(.title3)
                    .fontWeight(.bold)
                if let cost = item.servingCost {
                    Text((cost * item.numServings).formatted())
                        .font(.caption)
                        .italic()
                }
            }
            let nutrients = food.ingredients.nutrients * item.numServings
            MiniNutrientPieChart(text: nutrients.calories.value.formatted(), nutrients: nutrients)
                .frame(width: 56, height: 56)
                .font(.caption)
                .fontWeight(.bold)
        }.foregroundStyle(.primary)
    }
    
    private func recipeSummaryView(_ recipe: RecipeEntry) -> some View {
        // TODO
        VStack {
            Text("TODO")
        }
    }
    
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
    
    @ViewBuilder
    private func priceView(_ food: Food) -> some View {
        Section {
            VStack {
                HStack {
                    if let unwrappedValue = Binding($item.servingCost) {
                        CurrencyField(value: unwrappedValue)
                    } else {
                        Text(item.servingCost?.formatted() ?? "$0.00")
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
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            DatePicker(selection: $item.date, displayedComponents: [.hourAndMinute]) {
                EmptyView()
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Picker(selection: $item.meal) {
                ForEach(MealType.allCases, id: \.rawValue) { mealType in
                    Text(mealType.rawValue).tag(mealType.rawValue)
                }
            } label: {
                EmptyView()
            }.tint(.primary)
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
        SetAmountSheet(item: .init(meal: "Snacks"))
    }
}
