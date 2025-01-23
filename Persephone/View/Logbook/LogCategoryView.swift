//
//  LogCategoryView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/17/25.
//

import SwiftData
import SwiftUI

struct LogCategoryView: View {
    @Query(sort: \FoodLogEntry.date) private var foodEntries: [FoodLogEntry]
    @Query(sort: \RecipeLogEntry.date) private var recipeEntries: [RecipeLogEntry]
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    
    @State private var sheetType: SheetType? = nil
    
    var body: some View {
        let entries: [LogEntry] = foodEntries.filter({ navigationStore.logConfig.contains($0.date) })
            .filter({ navigationStore.logConfig.contains(meal: $0.meal) })
            .map({ .food($0) }) +
        recipeEntries.filter({ navigationStore.logConfig.contains($0.date) })
            .filter({ navigationStore.logConfig.contains(meal: $0.meal) })
            .map({ .recipe($0) })
        VStack(spacing: 0) {
            dateHeader()
                .padding([.top, .bottom], 8)
                .padding([.leading, .trailing], 24)
            Form {
                Section {
                    ForEach(entries, id: \.hashValue, content: entryView)
                } header: {
                    mealButton()
                }.headerProminence(.increased)
                HStack(alignment: .top) {
                    LogbookPieChart(nutrients: entries.nutrients, price: entries.cost ?? .zero)
                        .frame(width: 160, height: 160)
                    verticalMacroView(entries.nutrients)
                }
            }
            Spacer()
        }.navigationTitle("Logbook")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: UIColor.secondarySystemBackground))
            .toolbar(content: toolbarContent)
            .sheet(item: $sheetType) { type in
                switch type {
                case .amount(let entry):
                    LogEntryAmountSheet(item: .init(entry: entry))
                }
            }
    }
    
    @ViewBuilder
    private func dateHeader() -> some View {
        HStack {
            Button {
                navigationStore.logConfig.prev()
            } label: {
                Label("Prev", systemImage: "chevron.left").labelStyle(.iconOnly)
            }
            Spacer()
            Text(navigationStore.logConfig.date.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)
                .bold()
            Spacer()
            Button {
                navigationStore.logConfig.next()
            } label: {
                Label("Next", systemImage: "chevron.right").labelStyle(.iconOnly)
            }
        }
    }
    
    @ViewBuilder
    private func mealButton() -> some View {
        Menu {
            Button("All Entries") {
                navigationStore.logConfig.selectedMeal = nil
            }.disabled(navigationStore.logConfig.selectedMeal == nil)
            ForEach(LogbookView.Meals, id: \.hashValue) { meal in
                Button(meal) {
                    navigationStore.logConfig.selectedMeal = meal
                }.disabled(meal == navigationStore.logConfig.selectedMeal)
            }
        } label: {
            HStack {
                Text(navigationStore.logConfig.selectedMeal ?? "All Entries")
                    .font(.title2)
                    .bold()
                Image(systemName: "chevron.down")
                Spacer()
            }.clipShape(Rectangle())
        }.buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func entryView(_ entry: LogEntry) -> some View {
        Button {
            sheetType = .amount(entry)
        } label: {
            logEntryView(entry)
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
            .contextMenu {
                Button {
                    edit(entry)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button {
                    duplicate(entry)
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                Button(role: .destructive) {
                    delete(entry)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } preview: {
                switch entry {
                case .food(let food):
                    FoodLogEntryPreview(entry: food)
                        .padding()
                        .frame(width: 300)
                case .recipe(let recipe):
                    // TODO
                    RecipeEntryPreview(entry: recipe.recipe)
                        .padding()
                        .frame(width: 300)
                }
            }
            .swipeActions(allowsFullSwipe: false) {
                Button {
                    delete(entry)
                } label: {
                    Label("Delete", systemImage: "trash").tint(.red)
                }
                Button {
                    duplicate(entry)
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc").tint(.blue)
                }
                Button {
                    edit(entry)
                } label: {
                    Label("Edit", systemImage: "pencil").tint(.gray)
                }
            }
    }
    
    @ViewBuilder
    private func logEntryView(_ entry: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let brand = entry.brand {
                Text(brand)
                    .font(.subheadline)
                    .opacity(0.7)
            }
            Text(entry.name)
                .bold()
            HStack {
                Text(entry.nutrients.calories.formatted())
                Spacer()
                Text(entry.amount.formatted(maxDigits: 1))
            }.font(.subheadline)
                .fontWeight(.semibold)
            HStack {
                MacroSummaryView(entry.nutrients)
                    .italic()
                    .fontWeight(.semibold)
                Spacer()
                if let cost = entry.cost {
                    Text(cost.formatted())
                        .italic()
                }
            }.font(.subheadline)
        }
    }
    
    private func edit(_ entry: LogEntry) {
        navigationStore.push(LogViewType.edit(entry))
    }
    
    private func duplicate(_ entry: LogEntry) {
        switch entry {
        case .food(let food):
            let copy = FoodLogEntry(date: food.date,
                                    food: food.food,
                                    amount: food.amount,
                                    meal: food.meal,
                                    servingCost: food.servingCost)
            modelContext.insert(copy)
            navigationStore.push(LogViewType.edit(.food(copy)))
        case .recipe(let recipe):
            let copy = RecipeLogEntry(date: recipe.date,
                                      recipe: recipe.recipe,
                                      amount: recipe.amount,
                                      meal: recipe.meal)
            modelContext.insert(copy)
            navigationStore.push(LogViewType.edit(.recipe(recipe)))
            break
        }
    }
    
    private func delete(_ entry: LogEntry) {
        switch entry {
        case .food(let food):
            modelContext.delete(food)
        case .recipe(let recipe):
            modelContext.delete(recipe)
        }
    }
    
    @ViewBuilder
    private func verticalMacroView(_ nutrients: Nutrients) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Carbs: \(nutrients.get(.TotalCarbs)?.formatted(maxDigits: 1, includeSpace: false) ?? "0g")")
                .font(.title3)
                .foregroundStyle(Colors.carbs)
            Text("Fat: \(nutrients.get(.TotalFat)?.formatted(maxDigits: 1, includeSpace: false) ?? "0g")")
                .font(.title3)
                .foregroundStyle(Colors.fat)
            Text("Protein: \(nutrients.get(.Protein)?.formatted(maxDigits: 1, includeSpace: false) ?? "0g")")
                .font(.title3)
                .foregroundStyle(Colors.protein)
            Text("Sodium: \(nutrients.get(.Sodium)?.formatted(includeSpace: false) ?? "0mg")")
        }.bold()
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if navigationStore.logConfig.selectedMeal != nil {
                Button {
                    navigationStore.push(LogViewType.add())
                } label: {
                    Label("Add", systemImage: "plus")
                }
            } else {
                Menu {
                    ForEach(LogbookView.Meals, id: \.hashValue) { meal in
                        Button(meal) {
                            navigationStore.push(LogViewType.add(meal: meal))
                        }
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
    }
}

private enum SheetType: Identifiable {
    var id: String {
        switch self {
        case .amount(_):
            "Amount"
        }
    }
    
    case amount(_ entry: LogEntry)
}

struct MacroSummaryView: View {
    let nutrients: Nutrients
    
    init(_ nutrients: Nutrients) {
        self.nutrients = nutrients
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(nutrients.get(.TotalCarbs)?.formatted(includeSpace: false) ?? "0g")")
                .foregroundStyle(Colors.carbs)
            Text("·")
            Text("\(nutrients.get(.TotalFat)?.formatted(includeSpace: false) ?? "0g")")
                .foregroundStyle(Colors.fat)
            Text("·")
            Text("\(nutrients.get(.Protein)?.formatted(includeSpace: false) ?? "0g")")
                .foregroundStyle(Colors.protein)
            Text("·")
            Text("\(nutrients.get(.Sodium)?.formatted(includeSpace: false) ?? "0mg")")
        }
    }
}

struct LogEntryAmountSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var recentEntries: [FoodLogEntry]
    
    @State private var item: LogEntryItem
    
    init(item: LogEntryItem) {
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
        NavigationStack {
            Form {
                let units: [Amount.Unit] = {
                    switch item.type {
                    case .food:
                        let food = item.food!
                        let servingUnit = Amount.Unit(name: "Serving", abbreviation: food.servingSize.amount.unit?.abbreviation ?? "serving", modifier: food.servingSize.val / food.servingSize.amount.value.raw)
                        if food.servingSize.isMass {
                            return [servingUnit, Units.gram, Units.ounce, Units.pound]
                        } else {
                            return [servingUnit, Units.milliliter, Units.fluidounce]
                        }
                    case .recipe:
                        let recipe = item.recipe!
                        let servingUnit = Amount.Unit(name: "Serving", abbreviation: recipe.total.amount.unit?.abbreviation ?? "serving", modifier: recipe.total.val / recipe.total.amount.value.raw)
                        if recipe.total.isMass {
                            return [servingUnit, Units.gram, Units.ounce, Units.pound]
                        } else {
                            return [servingUnit, Units.milliliter, Units.fluidounce]
                        }
                    }
                }()
                ScaledAmountField(amount: $item.amount, units: units)
                switch item.type {
                case .food:
                    latestAmountView(item.food!)
                    ScaledFoodView(food: item.food!, size: item.size!, servingCost: item.servingCost, numServings: item.numServings)
                case .recipe:
                    otherAmountView(item.recipe!)
                    recipeView(item.recipe!)
                }
            }.navigationTitle("Edit Amount")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: toolbarContent)
        }.presentationDetents([.medium])
    }
    
    @ViewBuilder
    private func latestAmountView(_ food: Food) -> some View {
        let amounts = recentEntries.filter({ $0.food == food }).map({ $0.amount }).uniqued()
        if !amounts.isEmpty {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(amounts, id: \.hashValue) { amount in
                        Button(amount.formatted(maxDigits: 1)) {
                            // TODO fix bug with switching units
                            item.amount = amount
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func otherAmountView(_ recipe: RecipeEntry) -> some View {
        let amounts = (recipe.logEntries ?? []).sorted(by: { $0.date > $1.date }).map({ $0.amount }).uniqued()
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
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
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
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        LogCategoryView()
            .handleDestinations(navigationStore)
    }.environmentObject(navigationStore)
}
