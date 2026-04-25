//
//  MealView.swift
//  Persephone
//
//  Created by Zach Wassynger on 4/24/26.
//

import SwiftUI

struct MealView: View {
    @EnvironmentObject var navigationStore: NavigationStore
    
    let meal: Meal
    
    @State private var viewType: ViewType = .Ingredients
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        if !meal.notes.isEmpty {
                            Text(meal.notes)
                                .italic()
                        }
                        if let cost = meal.cost {
                            Text(cost.formatted())
                                .font(.headline)
                        }
                    }
                    Spacer()
                    NutrientPieChart(nutrients: meal.nutrients)
                        .frame(width: 140, height: 120)
                }
                Picker("View Type", selection: $viewType) {
                    Text("Food").tag(ViewType.Ingredients)
                    Text("Nutrients").tag(ViewType.Nutrients)
                }.pickerStyle(.segmented)
                switch viewType {
                case .Ingredients:
                    if meal.items.isEmpty {
                        Text("No Food Items")
                            .padding()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(meal.items.prefix(meal.items.count - 1)) { item in
                                foodItemEntry(item)
                                Divider()
                            }
                            foodItemEntry(meal.items[meal.items.count - 1])
                        }.padding([.leading, .trailing], 8)
                    }
                case .Nutrients:
                    NutrientsView(nutrients: meal.nutrients)
                        .padding([.leading, .trailing], 8)
                }
                Text("Created on \(meal.creationDate.formatted(date: .abbreviated, time: .standard))")
                    .font(.caption)
                    .fontWeight(.light)
            }.padding()
        }.navigationTitle(meal.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        navigationStore.push(LogViewType.editMeal(meal))
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
    }
    
    private func foodItemEntry(_ item: MealItem) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text(item.food.name)
                    .font(.headline)
                if let brand = item.food.brand {
                    Text(brand)
                        .font(.subheadline)
                        .italic()
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text((item.food.servingSize * item.numServings).formatted())
                    .font(.subheadline)
                if let cost = item.cost {
                    Text(cost.formatted())
                        .font(.subheadline)
                }
            }
        }.contentShape(Rectangle())
    }
    
    private enum ViewType {
        case Ingredients, Nutrients
    }
}

#Preview {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        let foods: [Food] = [
            .init(name: "Artisan Roll", metaData: .init(brand: "Kirkland", category: "Bread"), servingSize: .init(str: "1 loaf", val: 100), storeEntries: [.init(store: "Costco", cost: .usd(599), amount: .init(str: "1 package", val: 1200))]),
            .init(name: "Sharp Cheddar", metaData: .init(brand: "Adams Reserve", category: "Cheese"), servingSize: .init(str: "1 slice", val: 21)),
            .init(name: "Sliced Ham", metaData: .init(brand: "Kirkland", category: "Ham"), servingSize: .init(str: "2 slices", val: 56)),
            .init(name: "CFA Sauce", metaData: .init(brand: "Chick-Fil-A", category: "Sauce"), servingSize: .init(str: "2 tbsp", val: 31)),
            .init(name: "Jasmine Rice", metaData: .init(brand: "Botan", category: "Rice"), servingSize: .init(str: "45 g", val: 45)),
            .init(name: "Pork Tenderloin", metaData: .init(brand: "Swift", category: "Pork"), servingSize: .init(str: "4 oz", val: 112)),
            .init(name: "Green Beans", metaData: .init(brand: "Kirkland", category: "Vegetables"), servingSize: .init(str: "85 g", val: 85)),
        ]
        MealView(meal: .init(name: "Zach's Sandwich", notes: "Basic sandwich I guess", items: [
            .init(food: foods[0], servingCost: .usd(50)),
            .init(food: foods[1]),
            .init(food: foods[2], defaultAmount: .init(value: .raw(2))),
            .init(food: foods[3], defaultAmount: .init(value: .raw(5), unitStr: "g")),
        ])).handleDestinations(navigationStore)
    }.environmentObject(navigationStore)
}
