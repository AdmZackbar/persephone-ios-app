//
//  AddLogEntryView.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/7/26.
//

import SwiftData
import SwiftUI

struct AddLogEntryView: View {
    @EnvironmentObject var navigationStore: NavigationStore
    @Environment(\.modelContext) private var modelContext
    
    @Query private var foods: [Food]
    @Query private var recipes: [RecipeEntry]
    @Query private var meals: [Meal]
    @Query private var recentFoodEntries: [FoodLogEntry]
    
    @State var date: Date
    @State var mealType: String
    @State private var selection: [LogEntryItem]
    @State private var entryType: EntryType
    @State private var editItem: PersistentIdentifier?
    @State private var searchText: String
    
    init(date: Date, mealType: String) {
        self.date = date
        self.mealType = mealType
        self.selection = []
        self.entryType = .Food
        self.editItem = nil
        self.searchText = ""
        self._foods = Query(filter: #Predicate<Food> { food in
            food.metaData.retireDate == nil
        }, sort: \.name)
        self._recipes = Query(filter: #Predicate<RecipeEntry> { recipe in
            !recipe.retired
        }, sort: \.name)
        self._meals = Query(sort: \.name)
        self._recentFoodEntries = Query({
            var descriptor = FetchDescriptor<FoodLogEntry>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            descriptor.fetchLimit = 30
            return descriptor
        }())
    }
    
    var body: some View {
        Form {
            Section {
                if !selection.isEmpty {
                    ForEach(selection, id: \.hashValue) { entry in
                        Button {
                            editItem = entry.food?.id ?? entry.recipe?.id
                        } label: {
                            logEntryItemView(entry)
                                .contentShape(Rectangle())
                        }.buttonStyle(.plain)
                            .swipeActions {
                                Button(role: .destructive) {
                                    selection.removeAll(where: { $0 == entry })
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } else {
                    Text("Select foods or recipes to begin")
                        .font(.subheadline)
                        .italic()
                        .opacity(0.5)
                }
            } header: {
                DatePicker("Entries", selection: $date)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.primary)
            }
            Section {
                switch entryType {
                case .Food:
                    foodListView()
                case .Recipe:
                    recipeListView()
                case .Meal:
                    mealListView()
                }
            } header: {
                HStack {
                    Text("Select")
                    Spacer()
                    Picker("Type", selection: $entryType) {
                        ForEach(EntryType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }.pickerStyle(.segmented)
                        .frame(width: 250)
                }.foregroundStyle(.primary)
            }
        }.navigationTitle("Add Entries")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .searchable(text: $searchText)
            .sheet(isPresented: .isPresent($editItem), content: {
                if let index = selection.firstIndex(where: { $0.food?.id == editItem || $0.recipe?.id == editItem }) {
                    SaveAmountSheet(item: $selection[index])
                }
                else {
                    Text("Error getting item")
                }
            })
            .toolbar(content: toolbarContent)
    }
    
    private func logEntryItemView(_ item: LogEntryItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.food?.name ?? item.recipe?.name ?? "Name")
                    .fontWeight(.semibold)
                HStack {
                    if let food = item.food, let brand = food.brand {
                        Text(brand)
                    }
                }.font(.caption).italic()
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.amount.formatted())
                    .font(.subheadline)
                    .fontWeight(.bold)
                if let cost = item.servingCost {
                    Text((cost * item.numServings).formatted())
                        .font(.caption)
                        .italic()
                }
            }
            let nutrients = (item.food?.ingredients.nutrients ?? item.recipe?.nutrients ?? [:]) * item.numServings
            MiniNutrientPieChart(text: nutrients.calories.value.formatted(), nutrients: nutrients)
                .frame(width: 56, height: 56)
                .font(.caption)
                .fontWeight(.bold)
        }
    }
    
    @ViewBuilder
    private func foodListView() -> some View {
        var foodList: [Food] {
            if searchText.isEmpty {
                if recentFoodEntries.isEmpty {
                    return foods
                } else {
                    return recentFoodEntries.map({ $0.food }).uniqued()
                }
            } else {
                return (recentFoodEntries.map({ $0.food }) + foods).uniqued().filter(isFiltered)
            }
        }
        ForEach(foodList.prefix(30)) { food in
            Button {
                var entry: LogEntryItem = .init()
                entry.food = food
                entry.meal = mealType
                entry.date = date
                entry.servingCost = food.storeEntries.first(where: { $0.isAvailable })?.costPerServing(food.servingSize) ?? .zero
                entry.amount = recentFoodEntries.first(where: { $0.food == food })?.amount ?? food.servingSize.amount
                selection.append(entry)
                editItem = food.id
            } label: {
                // TODO
                HStack {
                    VStack(alignment: .leading) {
                        Text(food.name)
                            .bold()
                        if let brand = food.brand {
                            Text(brand)
                                .font(.subheadline)
                                .italic()
                        }
                    }
                    Spacer()
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
        }
    }
    
    private func isFiltered(_ food: Food) -> Bool {
        if searchText.isEmpty {
            return true
        }
        if food.name.localizedCaseInsensitiveContains(searchText) {
            return true
        }
        if let brand = food.brand, brand.localizedCaseInsensitiveContains(searchText) {
            return true
        }
        if let category = food.category, category.localizedCaseInsensitiveContains(searchText) {
            return true
        }
        return false
    }
    
    private func recipeListView() -> some View {
        ForEach(recipes) { recipe in
            Button {
                // TODO
            } label: {
                Text(recipe.name)
            }.buttonStyle(.plain)
        }
    }
    
    private func mealListView() -> some View {
        ForEach(meals) { meal in
            Button {
                // TODO
            } label: {
                Text(meal.name)
            }.buttonStyle(.plain)
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Menu {
                ForEach(MealType.allCases, id: \.rawValue) { t in
                    Button(t.rawValue) {
                        mealType = t.rawValue
                    }.disabled(mealType == t.rawValue)
                }
            } label: {
                HStack {
                    Text(mealType)
                        .font(.title)
                        .fontWeight(.bold)
                    Image(systemName: "chevron.down")
                }
            }
        }
        ToolbarItem(placement: .cancellationAction) {
            Button {
                navigationStore.pop()
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                // Can't use forEach and modify values
                for index in selection.indices {
                    var entry = selection[index]
                    // Make sure date and meal are up to date
                    entry.date = date
                    entry.meal = mealType
                    // Save to DB
                    entry.save(modelContext)
                }
                navigationStore.pop()
            } label: {
                Label("Save", systemImage: "checkmark")
            }.disabled(selection.isEmpty)
        }
    }
    
    private enum EntryType: String, Identifiable, CaseIterable, Hashable {
        var id: String {
            rawValue
        }
        
        case Food, Recipe, Meal
    }
    
    struct SaveAmountSheet: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.modelContext) private var modelContext
        
        @Query private var recentFoodEntries: [FoodLogEntry]
        
        @Binding var item: LogEntryItem
        
        init(item: Binding<LogEntryItem>) {
            self._item = item
            if let foodId = item.wrappedValue.food?.id {
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
                                .padding(.top, 8)
                        } else if let recipe = item.recipe {
                            recipeSummaryView(recipe)
                                .padding(.top, 8)
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
                    .toolbar(.hidden)
                    .presentationDetents([.height(380)])
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
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        AddLogEntryView(date: .now, mealType: "Snacks")
            .handleDestinations(navigationStore)
    }.environmentObject(navigationStore)
}
