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
            return List(items, id: \.hashValue) { item in
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
                    .contextMenu {
                        Button("Select") {
                            viewState = .SetAmount(foodItem: item)
                        }
                    } preview: {
                        FoodItemPreview(item: item)
                    }
            }.navigationTitle("Select Food")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
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
        private var amountValue: Quantity.Magnitude? {
            get {
                .parseString(amount)
            }
        }
        @State private var unit: Unit = .Serving
        @State private var notes: String = ""
        
        var body: some View {
            Form {
                Picker(selection: $unit) {
                    Text("serving").tag(Unit.Serving)
                    if foodItem.size.servingAmount.unit.isWeight {
                        Text("g").tag(Unit.Gram)
                        Text("oz").tag(Unit.Ounce)
                        Text("lb").tag(Unit.Pound)
                    } else {
                        Text("tsp").tag(Unit.Teaspoon)
                        Text("tbsp").tag(Unit.Tablespoon)
                        Text("cup").tag(Unit.Cup)
                        Text("mL").tag(Unit.Milliliter)
                        Text("fl oz").tag(Unit.FluidOunce)
                    }
                } label: {
                    TextField("amount", text: $amount)
                }
                TextField("notes", text: $notes, axis: .vertical)
                    .lineLimit(1...3)
                itemPreview(item: foodItem)
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
                                recipe.ingredients.append(RecipeIngredient(name: foodItem.name, food: foodItem, recipe: recipe, amount: Quantity(value: amountValue!, unit: unit), notes: notes.isEmpty ? nil : notes))
                            case .Edit(let ingredient):
                                ingredient.name = foodItem.name
                                ingredient.amount = Quantity(value: amountValue!, unit: unit)
                                ingredient.notes = notes.isEmpty ? nil : notes
                            }
                            dismiss()
                        }.disabled(amountValue == nil)
                    }
                }
        }
        
        private let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            return formatter
        }()
        
        private func itemPreview(item: FoodItem) -> some View {
            let scale = computeScale()
            return VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name).font(.headline).bold()
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    HStack(alignment: .top) {
                        Text(item.metaData.brand ?? "Generic Brand")
                            .font(.subheadline).italic()
                        Spacer()
                        if let tier = RatingTier.fromRating(rating: item.metaData.rating) {
                            Text("\(tier.rawValue) Tier")
                                .font(.subheadline).bold()
                        }
                    }
                    Text(item.details)
                        .font(.subheadline).lineLimit(1...7)
                }
                HStack(alignment: .top, spacing: 16) {
                    MacroChartView(nutrients: item.ingredients.nutrients, scale: scale)
                        .frame(width: 160, height: 120)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\((item.size.servingSizeAmount.value * scale).toString()) \(item.size.servingSizeAmount.unit.abbreviation)")
                            .bold()
                        Text("\((item.size.servingAmount.value * scale).toString())\(item.size.servingAmount.unit.abbreviation)")
                            .font(.subheadline).bold()
                    }
                }
            }
        }
        
        private func computeScale() -> Double {
            if let amountValue = amountValue {
                if unit.isWeight {
                    if let servingAmount = try? foodItem.size.servingAmount.convert(unit: .Gram).value.value {
                        return try! (Quantity(value: amountValue, unit: unit).convert(unit: .Gram).value / servingAmount).value
                    }
                } else if unit.isVolume {
                    if let servingAmount = try? foodItem.size.servingAmount.convert(unit: .Milliliter).value.value {
                        return try! (Quantity(value: amountValue, unit: unit).convert(unit: .Milliliter).value / servingAmount).value
                    }
                } else {
                    return amountValue.value
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
