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
    @Query private var instances: [FoodInstance]
    
    @State var date: Date
    @State var mealType: String
    @State private var selection: [LogEntryItem]
    @State private var entryType: EntryType
    @State private var editItem: UUID?
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
        }, sort: \.date, order: .reverse)
        self._instances = Query(sort: \.acquireDate)
    }
    
    var body: some View {
        Form {
            Section {
                if !selection.isEmpty {
                    ForEach(selection) { entry in
                        Button {
                            editItem = entry.id
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
                    FoodListView(mealType: mealType, foods: foods, instances: instances, searchText: $searchText, date: $date, selection: $selection, editItem: $editItem)
                case .Recipe:
                    RecipeListView(mealType: mealType, recipes: recipes, searchText: $searchText, date: $date, selection: $selection, editItem: $editItem)
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
                if let index = selection.firstIndex(where: { $0.id == editItem }) {
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
            let nutrients = item.nutrients
            MiniNutrientPieChart(text: nutrients.calories.value.formatted(), nutrients: nutrients)
                .padding(4)
                .frame(width: 56, height: 56)
                .font(.caption)
                .fontWeight(.bold)
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Menu {
                ForEach(MealType.allCases) { t in
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
        
        case Food, Recipe
    }
    
    struct FoodListView: View {
        @Query private var recentFoodEntries: [FoodLogEntry]
        
        let mealType: String
        let foods: [Food]
        let instances: [FoodInstance]
        @Binding var searchText: String
        @Binding var date: Date
        @Binding var selection: [LogEntryItem]
        @Binding var editItem: UUID?
        
        init(mealType: String, foods: [Food], instances: [FoodInstance], searchText: Binding<String>, date: Binding<Date>, selection: Binding<[LogEntryItem]>, editItem: Binding<UUID?>) {
            self.mealType = mealType
            self.foods = foods
            self.instances = instances
            self._searchText = searchText
            self._date = date
            self._selection = selection
            self._editItem = editItem
            self._recentFoodEntries = Query({
                var descriptor = FetchDescriptor<FoodLogEntry>(
                    predicate: #Predicate<FoodLogEntry> { entry in
                        entry.meal == mealType
                    },
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
                descriptor.fetchLimit = 30
                return descriptor
            }())
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
        
        var body: some View {
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
                let foodInstances = instances.filter({ $0.food == food })
                if foodInstances.isEmpty {
                    Button {
                        addFood(food)
                    } label: {
                        itemView(food)
                    }.buttonStyle(.plain)
                } else {
                    Menu {
                        ForEach(foodInstances, id: \.id) { instance in
                            Button {
                                addFood(food, instance: instance)
                            } label: {
                                Text("\(instance.source): \(instance.remaining.formatted())")
                            }
                        }
                        Button {
                            addFood(food)
                        } label: {
                            Text("New Entry")
                        }
                    } label: {
                        itemView(food)
                    }.buttonStyle(.plain)
                }
            }
        }
        
        private func addFood(_ food: Food, instance: FoodInstance? = nil) {
            var entry: LogEntryItem = .init()
            entry.type = .food
            entry.food = food
            entry.date = date
            entry.meal = mealType
            entry.servingCost = instance?.costPerServing ?? food.bestStoreEntry?.costPerServing(food.servingSize) ?? .zero
            entry.amount = recentFoodEntries.first(where: { $0.food == food })?.amount ?? food.servingSize.amount
            entry.instance = instance
            selection.append(entry)
            editItem = entry.id
        }
        
        private func itemView(_ food: Food) -> some View {
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
        }
    }
    
    struct RecipeListView: View {
        @Query private var recentEntries: [RecipeLogEntry]
        
        let mealType: String
        let recipes: [RecipeEntry]
        @Binding var searchText: String
        @Binding var date: Date
        @Binding var selection: [LogEntryItem]
        @Binding var editItem: UUID?
        
        init(mealType: String, recipes: [RecipeEntry], searchText: Binding<String>, date: Binding<Date>, selection: Binding<[LogEntryItem]>, editItem: Binding<UUID?>) {
            self.mealType = mealType
            self.recipes = recipes
            self._searchText = searchText
            self._date = date
            self._selection = selection
            self._editItem = editItem
            self._recentEntries = Query({
                var descriptor = FetchDescriptor<RecipeLogEntry>(
                    predicate: #Predicate<RecipeLogEntry> { entry in
                        if let recipe = entry.recipe {
                            return !recipe.retired && entry.meal == mealType
                        } else {
                            return entry.meal == mealType
                        }
                    },
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
                descriptor.fetchLimit = 30
                return descriptor
            }())
        }
        
        private func isFiltered(_ recipe: RecipeEntry) -> Bool {
            if searchText.isEmpty {
                return true
            }
            if recipe.name.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            return false
        }
        
        var body: some View {
            var recipeList: [RecipeEntry] {
                if searchText.isEmpty {
                    if recentEntries.isEmpty {
                        return recipes
                    } else {
                        return recentEntries.map({ $0.recipe }).uniqued()
                    }
                } else {
                    return (recentEntries.map({ $0.recipe }) + recipes).uniqued().filter(isFiltered)
                }
            }
            ForEach(recipeList.prefix(30)) { recipe in
                Button {
                    addRecipe(recipe)
                } label: {
                    itemView(recipe)
                }.buttonStyle(.plain)
            }
        }
        
        private func addRecipe(_ recipe: RecipeEntry) {
            var entry: LogEntryItem = .init()
            entry.type = .recipe
            entry.recipe = recipe
            entry.date = date
            entry.meal = mealType
            entry.servingCost = recipe.servingCost ?? .zero
            entry.amount = recipe.total.value
            entry.instance = nil
            selection.append(entry)
            editItem = entry.id
        }
        
        private func itemView(_ recipe: RecipeEntry) -> some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(recipe.name)
                        .bold()
                    Text(recipe.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .italic()
                }
                Spacer()
            }.contentShape(Rectangle())
        }
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
                        ScaledAmountField(amount: $item.cookedAmount, units: computeUnits())
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
                    if let instance = item.instance {
                        Section("Inventory") {
                            instanceView(instance)
                        }
                    } else if let food = item.food {
                        Section {
                            priceView(food)
                        }
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
        
        @ViewBuilder
        private func recipeSummaryView(_ recipe: RecipeEntry) -> some View {
            let nutrients = recipe.servingNutrients * item.numServings
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
                            Text((amount * ( 1)).formatted(maxDigits: 1))
                                .bold()
                        }.buttonStyle(.glass)
                    }
                }
            }.scrollIndicators(.hidden)
                .scrollClipDisabled()
                // Line up with form sections
                .padding([.leading, .trailing], -14)
        }
        
        private func instanceView(_ instance: FoodInstance) -> some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(instance.remaining.formatted())
                        .bold()
                    Text(instance.source)
                        .font(.subheadline)
                        .italic()
                    Text(instance.acquireDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .fontWeight(.light)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(instance.cost.formatted())
                }
            }
        }
        
        @ViewBuilder
        private func priceView(_ food: Food) -> some View {
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
                        ForEach(food.storeEntries, id: \.hashValue) { storeEntry in
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

#Preview(traits: .sampleData) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        AddLogEntryView(date: .now, mealType: "Snacks")
            .handleDestinations(navigationStore)
    }.environmentObject(navigationStore)
}
