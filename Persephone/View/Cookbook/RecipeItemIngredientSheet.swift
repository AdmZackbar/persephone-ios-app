//
//  AddItemIngredientSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 8/7/24.
//

import SwiftData
import SwiftUI

struct RecipeItemIngredientSheet: View {
    private enum ViewState {
        case SelectFood
        case SetAmount(foodItem: FoodItem)
    }
    
    enum Mode {
        case Add
        case Edit(ingredient: RecipeIngredient)
    }
    
    let recipe: Recipe
    let mode: Mode
    
    @State private var viewState: ViewState
    
    init(recipe: Recipe, mode: Mode = .Add) {
        self.recipe = recipe
        self.mode = mode
        switch mode {
        case .Add:
            viewState = .SelectFood
        case .Edit(let ingredient):
            viewState = .SetAmount(foodItem: ingredient.food!)
        }
    }
    
    var body: some View {
        NavigationStack {
            switch viewState {
            case .SelectFood:
                SelectFoodView(viewState: $viewState)
            case .SetAmount(let foodItem):
                SetAmountView(recipe: recipe, mode: mode, foodItem: foodItem, viewState: $viewState)
            }
        }.presentationDetents([.large])
    }
    
    private struct SelectFoodView: View {
        @Environment(\.dismiss) var dismiss
        
        @Query(sort: \FoodItem.name) var foodItems: [FoodItem]
        
        @Binding private var viewState: ViewState
        @State private var search: String = ""
        
        var body: some View {
            let items = foodItems.filter({ item in search.isEmpty || item.name.localizedCaseInsensitiveContains(search) })
            return Form {
                List(items, id: \.name) { item in
                    Button {
                        viewState = .SetAmount(foodItem: item)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                            HStack {
                                if let brand = item.metaData.brand {
                                    Text(brand).font(.subheadline).italic()
                                }
                                Spacer()
                            }
                        }.contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }.navigationTitle("Select Food")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .searchable(text: $search)
                .overlay {
                    if items.isEmpty {
                        Text(foodItems.isEmpty ? "No food in database" : "No food matches search")
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
        
        init(viewState: Binding<ViewState>) {
            self._viewState = viewState
        }
    }

    private struct SetAmountView: View {
        @Environment(\.dismiss) var dismiss
        
        let recipe: Recipe
        let mode: Mode
        let foodItem: FoodItem
        
        @Binding private var viewState: ViewState
        
        @State private var amount: String = ""
        private var amountValue: FoodAmount.Value? {
            get {
                .parseString(amount)
            }
        }
        @State private var unit: FoodUnit = .Custom(name: "Serving")
        @State private var notes: String = ""
        
        var body: some View {
            Form {
                Section {
                    Picker(selection: $unit) {
                        Text("serving").tag(FoodUnit.Custom(name: "Serving"))
                        if foodItem.size.servingAmount.unit.isWeight() {
                            Text("g").tag(FoodUnit.Gram)
                            Text("oz").tag(FoodUnit.Ounce)
                            Text("lb").tag(FoodUnit.Pound)
                        } else {
                            Text("tsp").tag(FoodUnit.Teaspoon)
                            Text("tbsp").tag(FoodUnit.Tablespoon)
                            Text("cup").tag(FoodUnit.Cup)
                            Text("mL").tag(FoodUnit.Milliliter)
                            Text("fl oz").tag(FoodUnit.FluidOunce)
                        }
                    } label: {
                        TextField("amount", text: $amount)
                    }
                    TextField("notes", text: $notes, axis: .vertical)
                        .lineLimit(1...3)
                }
                Section {
                    NutrientTableView(nutrients: foodItem.ingredients.nutrients, scale: computeScale())
                }
            }.navigationTitle(foodItem.name)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .onAppear {
                    switch mode {
                    case .Edit(let ingredient):
                        amount = ingredient.amount.value.toString()
                        unit = ingredient.amount.unit
                        notes = ingredient.notes ?? ""
                    default:
                        break
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Back") {
                            switch mode {
                            case .Add:
                                viewState = .SelectFood
                            case .Edit(_):
                                dismiss()
                            }
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") {
                            switch mode {
                            case .Add:
                                recipe.ingredients.append(RecipeIngredient(name: foodItem.name, food: foodItem, recipe: recipe, amount: FoodAmount(value: amountValue!, unit: unit), notes: notes.isEmpty ? nil : notes))
                            case .Edit(let ingredient):
                                ingredient.amount = FoodAmount(value: amountValue!, unit: unit)
                                ingredient.notes = notes.isEmpty ? nil : notes
                            }
                            dismiss()
                        }.disabled(amountValue == nil)
                    }
                }
        }
        
        private func computeScale() -> Double {
            if let amountValue = amountValue {
                switch unit {
                case .Custom(_):
                    return amountValue.toValue()
                default:
                    if unit.isWeight() {
                        if let servingAmount = try? foodItem.size.servingAmount.toGrams().value.toValue() {
                            return try! (FoodAmount(value: amountValue, unit: unit).toGrams().value / servingAmount).toValue()
                        }
                    } else if unit.isVolume() {
                        if let servingAmount = try? foodItem.size.servingAmount.toMilliliters().value.toValue() {
                            return try! (FoodAmount(value: amountValue, unit: unit).toMilliliters().value / servingAmount).toValue()
                        }
                    }
                }
            }
            return 1
        }
        
        init(recipe: Recipe, mode: Mode, foodItem: FoodItem, viewState: Binding<ViewState>) {
            self.recipe = recipe
            self.mode = mode
            self.foodItem = foodItem
            self._viewState = viewState
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    createTestFoodItem(container.mainContext)
    let recipe = createTestRecipeItem(container.mainContext)
    return RecipeItemIngredientSheet(recipe: recipe).modelContainer(container)
}
