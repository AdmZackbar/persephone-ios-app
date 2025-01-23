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
    
    @EnvironmentObject
    private var navigationStore: NavigationStore
    
//    @State private var sheetType: SheetType? = nil
    
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
//            .sheet(item: $sheetType) { type in
//                switch type {
//                case .EditFoodItem(let entry):
//                    EditAmountSheet(item: .init(entry: entry))
//                }
//            }
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
            // TODO show sheet
        } label: {
            switch entry {
            case .food(let food):
                foodLogEntry(food)
            case .recipe(let recipe):
                recipeLogEntry(recipe)
            }
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
    private func foodLogEntry(_ entry: FoodLogEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let brand = entry.food.brand {
                Text(brand)
                    .font(.subheadline)
                    .opacity(0.7)
            }
            Text(entry.food.name)
                .bold()
            HStack {
                Text(entry.nutrients.calories.formatted(maxDigits: 0, includeSpace: true))
                Spacer()
                Text(entry.amount.formatted(includeSpace: true))
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
        }.contentShape(Rectangle())
    }
    
    @ViewBuilder
    private func recipeLogEntry(_ entry: RecipeLogEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.recipe.name)
                .bold()
            HStack {
                Text(entry.nutrients.calories.formatted(maxDigits: 0, includeSpace: true))
                Spacer()
                Text(entry.size.formatted())
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
        }.contentShape(Rectangle())
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
                                      amountScale: recipe.amountScale,
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
            Text("Carbs: \(nutrients.get(.TotalCarbs)?.formatted(maxDigits: 1) ?? "0g")")
                .font(.title3)
                .foregroundStyle(Colors.carbs)
            Text("Fat: \(nutrients.get(.TotalFat)?.formatted(maxDigits: 1) ?? "0g")")
                .font(.title3)
                .foregroundStyle(Colors.fat)
            Text("Protein: \(nutrients.get(.Protein)?.formatted(maxDigits: 1) ?? "0g")")
                .font(.title3)
                .foregroundStyle(Colors.protein)
            Text("Sodium: \(nutrients.get(.Sodium)?.formatted(maxDigits: 0) ?? "0mg")")
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

struct MacroSummaryView: View {
    let nutrients: Nutrients
    
    init(_ nutrients: Nutrients) {
        self.nutrients = nutrients
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(nutrients.get(.TotalCarbs)?.formatted(maxDigits: 0) ?? "0g")")
                .foregroundStyle(Colors.carbs)
            Text("·")
            Text("\(nutrients.get(.TotalFat)?.formatted(maxDigits: 0) ?? "0g")")
                .foregroundStyle(Colors.fat)
            Text("·")
            Text("\(nutrients.get(.Protein)?.formatted(maxDigits: 0) ?? "0g")")
                .foregroundStyle(Colors.protein)
            Text("·")
            Text("\(nutrients.get(.Sodium)?.formatted(maxDigits: 0) ?? "0mg")")
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
