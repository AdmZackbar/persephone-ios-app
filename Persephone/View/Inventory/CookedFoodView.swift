//
//  CookedFoodView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/15/25.
//

import SwiftUI

struct CookedFoodView: View {
    @EnvironmentObject var navigationStore: NavigationStore
    
    let cookedFood: CookedFood
    
    @State private var sizeType: SizeType = .serving
    
    var body: some View {
        VStack {
            Form {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total:")
                            Text((cookedFood.size.servingSizeAmount * cookedFood.size.numServings).formatted(maxDigits: 2, includeSpace: true))
                            Text(cookedFood.size.totalAmount.formatted())
                        }
                        VStack(alignment: .leading) {
                            Text("Serving:")
                            Text(cookedFood.size.servingSizeAmount.formatted(includeSpace: true))
                            Text(cookedFood.size.servingAmount.formatted(maxDigits: 1))
                        }
                        Spacer()
                        Gauge(value: cookedFood.remaining, in: 0...cookedFood.size.totalAmount.value.value) {
                            Text("\(cookedFood.remaining.formatted())g")
                        }.gaugeStyle(.accessoryCircularCapacity)
                    }
                }
                if let instructions = cookedFood.recipe?.instructions {
                    Section("Instructions") {
                        ForEach(instructions, id: \.hashValue) { part in
                            VStack(alignment: .leading) {
                                Text(part.header)
                                Text(part.details)
                            }
                        }
                    }
                }
                if !cookedFood.notes.isEmpty {
                    Section("Notes") {
                        Text(cookedFood.notes)
                    }
                }
                Section("Ingredients") {
                    ForEach(cookedFood.ingredients, id: \.hashValue, content: CookedFoodIngredientEntryView.init)
                }
                Section("Nutrition") {
                    Picker("", selection: $sizeType) {
                        ForEach(SizeType.allCases) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }.pickerStyle(.segmented)
                    let scale: Double = {
                        switch sizeType {
                        case .whole:
                            1
                        case .serving:
                            1 / cookedFood.size.numServings
                        }
                    }()
                    LogbookPieChart(nutrients: cookedFood.totalNutrition * scale, price: (cookedFood.totalCost ?? .Cents(0)) * scale)
                        .frame(width: 180, height: 180)
                    NutrientTableView(nutrients: cookedFood.totalNutrition * scale)
                }
            }
        }.navigationTitle(cookedFood.name)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: UIColor.secondarySystemBackground))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(cookedFood.name)
                            .bold()
                        Text(cookedFood.date.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        navigationStore.push(InventoryView.ViewType.editCookedFood(food: cookedFood))
                    }
                }
            }
    }
    
    private enum SizeType: String, Identifiable, CaseIterable {
        var id: String {
            rawValue
        }
        
        case whole
        case serving
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack {
        CookedFoodView(cookedFood: .init(
            name: "Grilled Flank Steak",
            ingredients: [
                .init(
                    foodItem: .init(
                        name: "Flank Steak",
                        metaData: .init(brand: "Publix"),
                        ingredients: .init(nutrients: [.Energy: .calories(120), .TotalFat: .grams(4), .Protein: .grams(14), .TotalCarbs: .grams(1), .Sodium: .milligrams(55)]),
                        size: .init(totalAmount: .grams(448), numServings: 4, servingSize: "4 oz"),
                        storeEntries: [
                            .init(storeName: "Publix", costType: .PerAmount(cost: .Cents(1599), amount: .init(value: .Raw(1), unit: .Pound)))
                        ]),
                    amount: .Raw(3.56),
                    unitPrice: .Cents(1599))],
            notes: "Some notes about the prep",
            remaining: 200,
            size: .init(totalAmount: .grams(400), numServings: 4.5, servingSize: "1 portion")
        )
        ).environmentObject(navigationStore)
    }
}
