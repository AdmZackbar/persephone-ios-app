//
//  RecipeEntryView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/20/25.
//

import SwiftUI

struct RecipeEntryView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    
    let entry: RecipeEntry
    
    var body: some View {
        Form {
            let servingNutrients = entry.nutrients / entry.total.amount.value.raw
            Section {
                HStack(alignment: .top) {
                    servingSizeView()
                    Spacer()
                    NutrientPieChart(nutrients: servingNutrients)
                        .frame(width: 150, height: 120)
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Amount")
                            .font(.subheadline)
                            .opacity(0.7)
                        Text(entry.total.amount.formatted(maxDigits: 2).capitalized)
                            .font(.headline)
                        Text(entry.total.value.formatted(maxDigits: 1, includeSpace: false))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                    // TODO
                    Gauge(value: entry.usedScale, in: 0...1) {
                        Text(entry.total.value.formatted())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }.gaugeStyle(.accessoryCircularCapacity)
                }
                if let notes = entry.notes {
                    Text(notes)
                        .font(.subheadline)
                        .italic()
                }
            }
            Section("Ingredients") {
                ForEach(entry.ingredients, id: \.hashValue, content: RecipeEntryIngredientListEntryView.init)
            }
            Section("Per Serving") {
                NutrientsView(nutrients: servingNutrients)
            }
        }.navigationTitle(entry.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbarContent)
    }
    
    @ViewBuilder
    private func servingSizeView() -> some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Serving Size")
                    .font(.subheadline)
                    .opacity(0.7)
                Text("1 \(entry.total.amount.unitStr!.capitalized)")
                    .font(.title3)
                    .bold()
                Text((entry.total.value / entry.total.amount.value.raw).formatted())
                    .fontWeight(.semibold)
                if let cost = entry.cost {
                    Text((cost / entry.total.amount.value.raw).formatted())
                        .italic()
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack {
                Text(entry.date.formatted(date: .long, time: .shortened))
                    .font(.caption)
                    .italic()
                Text(entry.name)
                    .font(.headline)
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button("Edit") {
                navigationStore.push(CookbookViewType.editEntry(entry))
            }
        }
    }
}

struct RecipeEntryIngredientListEntryView: View {
    let ingredient: RecipeEntryIngredient
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let brand = ingredient.food.brand {
                    Text(brand)
                        .opacity(0.7)
                }
                Spacer()
                if let cost = ingredient.cost {
                    Text(cost.formatted())
                        .italic()
                }
            }.font(.subheadline)
            HStack {
                Text(ingredient.food.name)
                    .font(.headline)
                Spacer()
                Text(ingredient.amount.formatted(maxDigits: 1))
            }
            HStack {
                MacroSummaryView(ingredient.nutrients)
                Spacer()
                Text(ingredient.nutrients.calories.formatted())
            }.font(.subheadline)
                .fontWeight(.semibold)
            if let notes = ingredient.notes {
                Text(notes)
                    .font(.subheadline)
                    .italic()
            }
        }
    }
}

#Preview {
    @Previewable @StateObject var navigationStore = NavigationStore()
    let entry: RecipeEntry = .init(name: "Baked Pork Tenderloin",
                                   notes: "In the oven for 20 min",
                                   total: .init(str: "2 tenderloins", val: 907),
                                   ingredients: [
                                     .init(
                                         food: .init(
                                             name: "Pork Tenderloin",
                                             metaData: .init(brand: "Publix", category: "Beef"),
                                             ingredients: .init(nutrients: [.Energy: 170, .Protein: 22, .TotalFat: 7]),
                                             servingSize: .init(str: "4 oz", val: 112)),
                                         amount: .init(value: .raw(1102), unit: Units.gram),
                                         servingCost: .usd(134),
                                         notes: "Tenderized and trimmed")
                                   ])
    NavigationStack(path: $navigationStore.path) {
        RecipeEntryView(entry: entry)
            .handleDestinations(navigationStore)
    }.environmentObject(navigationStore)
}
