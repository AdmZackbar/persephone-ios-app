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
    
    let recipe: Recipe
    
    @State private var viewState: ViewState = .SelectFood
    
    var body: some View {
        NavigationStack {
            switch viewState {
            case .SelectFood:
                SelectFoodView(viewState: $viewState)
            case .SetAmount(let foodItem):
                SetAmountView(recipe: recipe, foodItem: foodItem, viewState: $viewState)
            }
        }.presentationDetents([.medium])
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
                        Text(item.name)
                    }
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
        let foodItem: FoodItem
        
        @Binding private var viewState: ViewState
        
        @State private var amount: String = ""
        private var amountValue: FoodAmount.Value? {
            get {
                if let match = amount.wholeMatch(of: /([\d.]+)\s*\/\s*([\d.]+)/),
                    let num = Double(match.1),
                    let den = Double(match.2) {
                    return .Rational(num: num, den: den)
                } else if let match = amount.wholeMatch(of: /([\d.]+)/),
                          let value = Double(match.1) {
                    return .Raw(value)
                }
                return nil
            }
        }
        @State private var unit: FoodUnit = .Custom(name: "Serving")
        
        var body: some View {
            Form {
                Picker(selection: $unit) {
                    Text("serving").tag(FoodUnit.Custom(name: "Serving"))
                    if foodItem.size.servingAmount.unit.isWeight() {
                        Text("g").tag(FoodUnit.Gram)
                        Text("oz").tag(FoodUnit.Ounce)
                    } else {
                        Text("mL").tag(FoodUnit.Milliliter)
                        Text("fl oz").tag(FoodUnit.FluidOunce)
                    }
                } label: {
                    TextField("amount", text: $amount)
                }
            }.navigationTitle(foodItem.name)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Back") {
                            viewState = .SelectFood
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") {
                            recipe.ingredients.append(RecipeIngredient(name: foodItem.name, food: foodItem, recipe: recipe, amount: FoodAmount(value: amountValue!, unit: unit)))
                            dismiss()
                        }.disabled(amountValue == nil)
                    }
                }
        }
        
        init(recipe: Recipe, foodItem: FoodItem, viewState: Binding<ViewState>) {
            self.recipe = recipe
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
