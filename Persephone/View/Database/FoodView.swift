//
//  FoodView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/17/25.
//

import SwiftUI

struct FoodView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    
    let food: Food
    
    var body: some View {
        Form {
            Section {
                HStack(alignment: .top, spacing: 16) {
                    NutrientPieChart(nutrients: food.ingredients.nutrients)
                        .frame(width: 120, height: 120)
                    Divider()
                    storeEntriesView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }.padding(.top, 8)
            } header: {
                let category = food.metaData.category
                VStack(alignment: .leading, spacing: 8) {
                    if let retireDate = food.metaData.retireDate {
                        Text("Retired: \(retireDate.formatted(date: .long, time: .omitted))")
                            .italic()
                    }
                    HStack {
                        if !category.isEmpty {
                            Label(category, systemImage: "tag.fill")
                        }
                        Spacer()
                        Text("\(food.rating?.rawValue ?? "No") Tier")
                    }.fontWeight(.semibold)
                }.font(.subheadline)
                    .padding([.leading, .trailing], -12)
            }.headerProminence(.increased)
            if let notes = food.notes {
                Section("Notes") {
                    Text(notes)
                        .font(.subheadline)
                        .italic()
                }
            }
            Section {
                NutrientsView(nutrients: food.ingredients.nutrients)
            } header: {
                HStack(spacing: 4) {
                    Text("Serving Size:")
                    Spacer()
                    Text(food.servingSize.amount.formatted(includeSpace: true))
                    Text("(\(food.servingSize.value.formatted()))")
                        .italic()
                }.font(.headline)
                    .fontWeight(.semibold)
            }.headerProminence(.increased)
            Section {
                let all = food.ingredients.all.isEmpty ? "None Recorded" : food.ingredients.all
                Text(all)
                    .font(.subheadline)
                    .italic()
                Text("Allergens: \(food.ingredients.allergens.isEmpty ? "None" : food.ingredients.allergens)")
                    .bold()
            } header: {
                Text("Ingredients")
                    .font(.headline)
                    .fontWeight(.semibold)
            } footer: {
                HStack {
                    Text("Created: \(food.metaData.timestamp.formatted())")
                    Spacer()
                    if let barcode = food.metaData.barcode {
                        Text(barcode)
                    }
                }.font(.caption)
                    .padding(.top, 8)
                    .padding([.leading, .trailing], -8)
            }.headerProminence(.increased)
        }.navigationTitle(food.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbarContent)
    }
    
    @ViewBuilder
    private func storeEntriesView() -> some View {
        if food.storeEntries.count > 1 {
            TabView {
                ForEach(food.storeEntries, id: \.hashValue, content: storeEntryView)
            }.tabViewStyle(.page)
        } else if let storeEntry = food.storeEntries.first {
            storeEntryView(storeEntry)
        } else {
            Text("No Store Entries")
        }
    }
    
    @ViewBuilder
    private func storeEntryView(_ storeEntry: Food.StoreEntry) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(storeEntry.store)
                    .font(.headline)
                HStack(spacing: 4) {
                    Text(storeEntry.amount.amount.formatted(includeSpace: true))
                    Text("(\(storeEntry.amount.value.formatted()))")
                }.font(.subheadline)
                Text(storeEntry.cost.formatted())
                    .font(.subheadline)
                    .italic()
                HStack(spacing: 4) {
                    if !storeEntry.isAvailable {
                        Text("Retired")
                    }
                    if storeEntry.isSale {
                        Text("Sale")
                    }
                }.font(.caption)
                Spacer()
            }
            Spacer()
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack {
                Text(food.name)
                    .bold()
                if let brand = food.brand {
                    Text(brand)
                        .italic()
                        .font(.subheadline)
                }
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button("Edit") {
                navigationStore.push(FoodViewType.editFood(food))
            }
        }
    }
}

#Preview {
    @Previewable @StateObject var navigationStore = NavigationStore()
    let food = Food(
        name: "Test Food",
        metaData: .init(barcode: "0123456789", brand: "Some Brand", category: "Bread", notes: "Preparation: cook at 375 F for 12-14 minutes.", rating: 8),
        ingredients: .init(
            nutrients: [
                .Energy: 120,
                .TotalFat: 3.5,
                .SaturatedFat: 2,
                .PolyunsaturatedFat: 0.5,
                .Cholesterol: 50,
                .Sodium: 255,
                .TotalCarbs: 12,
                .DietaryFiber: 1,
                .TotalSugars: 0.5,
                .Protein: 5,
                .Calcium: 20,
                .Potassium: 15
            ],
            all: "Salt, Milk, Water, Pectin (for something or other).",
            allergens: "Milk"
        ),
        servingSize: .init(str: "1 unit", val: 35),
        storeEntries: [
            .init(store: "Store 1", cost: .usd(599), amount: .init(str: "1 container", val: 1600)),
            .init(store: "Store 2", cost: .usd(1099), amount: .init(str: "2 containers", val: 3200)),
            .init(store: "Store 3", cost: .usd(1000), amount: .init(str: "1 lb", val: 500))
        ]
    )
    NavigationStack(path: $navigationStore.path) {
        FoodView(food: food)
            .handleDestinations(navigationStore)
    }.environmentObject(navigationStore)
}
