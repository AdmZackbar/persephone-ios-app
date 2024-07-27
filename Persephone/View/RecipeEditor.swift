//
//  RecipeEditor.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/16/24.
//

import SwiftData
import SwiftUI

struct RecipeEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    
    var recipe: Recipe?
    
    @State private var name: String = ""
    @State private var details: String = ""
    @State private var ingredients: [Ingredient] = []
    @State private var nextIngredient: String = ""
    private var nextIngredientInvalid: Bool {
        get {
            let amountAndUnit = /([\d.]+)\s*(\w+)/
            if let match = nextIngredient.firstMatch(of: amountAndUnit) {
                let amount = Double(match.1)
                let unit = parseUnit(match.2.string)
                let iName = nextIngredient[match.range.upperBound...].string.trimmingCharacters(in: .whitespaces)
                if amount != nil && unit != nil && !iName.isEmpty {
                    return false
                }
            }
            return true
        }
    }
    @State private var sections: [RecipeSection] = []
    @State private var nextSectionHeader: String = ""
    @State private var nextSectionDetails: String = ""
    @State private var prepTime: Double = 0.0
    @State private var cookTime: Double = 0.0
    @State private var servingSize: String = ""
    @State private var numServings: Double = 0.0
    @State private var cookedWeight: Double = 0.0
    
    let durationFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.zeroSymbol = ""
        return formatter
    }()
    
    var body: some View {
        Form {
            Section("Name and Description") {
                TextField("required", text: $name).textInputAutocapitalization(.words)
                TextField("description", text: $details, axis: .vertical).textInputAutocapitalization(.sentences).lineLimit(3...5)
            }
            Section("Ingredients") {
                List(ingredients.sorted(by: { x, y in
                    x.name.lowercased() < y.name.lowercased()
                }), id: \.self.name) { ingredient in
                    HStack(spacing: 4) {
                        Text(durationFormatter.string(for: ingredient.amount)!).bold()
                        Text(ingredient.unit.getAbbreviation()).bold()
                        Text(ingredient.name).padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                    }.swipeActions {
                        Button("Delete", role: .destructive) {
                            deleteIngredient(ingredient)
                        }
                    }
                }
                HStack {
                    TextField("Add Ingredient...", text: $nextIngredient).textInputAutocapitalization(.words).onSubmit(parseNextIngredient)
                    Button(action: parseNextIngredient) {
                        Label("Add", systemImage: "plus").labelStyle(.iconOnly)
                    }.disabled(nextIngredientInvalid)
                }
            }
            Section("Times") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        HStack {
                            Text("Prep:")
                            TextField("minutes", value: $prepTime, formatter: durationFormatter)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                            if prepTime > 0 {
                                Text("min").italic()
                            }
                        }.frame(minWidth: 100)
                        Divider().padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                        HStack {
                            Text("Cook:")
                            TextField("minutes", value: $cookTime, formatter: durationFormatter)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                            if cookTime > 0 {
                                Text("min").italic()
                            }
                        }
                    }
                    if prepTime > 0 || cookTime > 0 {
                        Divider()
                        HStack {
                            Text("Total:")
                            Spacer()
                            Text("\(durationFormatter.string(for: prepTime + cookTime)!)  minutes")
                        }.italic().padding(EdgeInsets(top: 6, leading: 0, bottom: 10, trailing: 0)).opacity(0.5)
                    }
                }
            }
            Section("Sizing") {
                HStack {
                    Text("Serving Size:").fixedSize(horizontal: true, vertical: false)
                    TextField("required", text: $servingSize)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Num. Servings:").fixedSize(horizontal: true, vertical: false)
                    TextField("required", value: $numServings, formatter: durationFormatter)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                    if numServings > 0 {
                        Text("servings").italic()
                    }
                }
                HStack {
                    Text("Total Weight (cooked):").fixedSize(horizontal: true, vertical: false)
                    TextField("optional", value: $cookedWeight, formatter: durationFormatter)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                    if cookedWeight > 0 {
                        Text("g").italic()
                    }
                }
            }
            Section("Instructions") {
                List(sections, id: \.self.header) { section in
                    DisclosureGroup {
                        Text(section.details).font(.subheadline).fontWeight(.thin)
                    } label: {
                        Text(section.header).bold()
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    deleteSection(section)
                                }
                            }
                    }
                }
                TextField("Header", text: $nextSectionHeader).textInputAutocapitalization(.words).bold()
                TextEditor(text: $nextSectionDetails)
                    .textInputAutocapitalization(.sentences)
                    .frame(height: 100)
                    .onSubmit(parseNextSection)
                Button("Add Section", action: parseNextSection)
                    .disabled(nextSectionDetails.isEmpty)
            }
        }.navigationTitle(recipe != nil ? "Edit Recipe" : "Create Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: save) {
                        Text("Save")
                    }.disabled(name.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: discard) {
                        Text("Discard")
                    }
                }
            }
            .onAppear {
                if let recipe = recipe {
                    name = recipe.name
                    details = recipe.metaData.details
                    ingredients = recipe.ingredients.map({ ingredient in
                        Ingredient(name: ingredient.name, food: ingredient.food, amount: ingredient.amount.value, unit: ingredient.amount.unit)
                    })
                    sections = recipe.instructions
                    prepTime = recipe.metaData.prepTime
                    cookTime = recipe.metaData.cookTime
                    servingSize = recipe.size.servingSize
                    numServings = recipe.size.numServings
                    cookedWeight = recipe.size.cookedAmount?.value ?? 0
                }
            }
    }
    
    private func parseNextIngredient() {
        let amountAndUnit = /([\d.]+)\s*(\w+)/
        if let match = nextIngredient.firstMatch(of: amountAndUnit) {
            let amount = Double(match.1)
            let unit = parseUnit(match.2.string)
            let iName = nextIngredient[match.range.upperBound...].string.trimmingCharacters(in: .whitespaces)
            if amount != nil && unit != nil && !iName.isEmpty {
                ingredients.append(Ingredient(name: iName, amount: amount!, unit: unit!))
                nextIngredient = ""
            }
        }
    }
    
    private func parseUnit(_ unit: String) -> FoodUnit? {
        for foodUnit in FoodUnit.allCases {
            for unitName in getUnitNames(foodUnit) {
                if unit.caseInsensitiveCompare(unitName) == .orderedSame {
                    return foodUnit
                }
            }
        }
        return nil
    }
    
    private func getUnitNames(_ unit: FoodUnit) -> [String] {
        switch unit {
        case .Calorie:
            return ["cal", "calorie", "calories"]
        case .Ounce:
            return ["oz", "ounce", "ounces"]
        case .Pound:
            return ["lb", "lbs", "pound", "pounds"]
        case .Microgram:
            return ["mcg", "microgram", "micrograms"]
        case .Milligram:
            return ["mg", "milligram", "milligrams"]
        case .Gram:
            return ["g", "gram", "grams"]
        case .Kilogram:
            return ["kg", "kilogram", "kilograms"]
        case .Teaspoon:
            return ["tsp", "teaspoon", "teaspoons"]
        case .Tablespoon:
            return ["tbsp", "tablespoon", "tablespoons"]
        case .FluidOunce:
            return ["fl oz", "fluid ounce", "fluid ounces"]
        case .Cup:
            return ["c", "cup", "cups"]
        case .Pint:
            return ["pint", "pints"]
        case .Quart:
            return ["qt", "quart", "quarts"]
        case .Gallon:
            return ["gal", "gallon", "gallons"]
        case .Milliliter:
            return ["mL", "milliliter", "milliliters"]
        case .Liter:
            return ["L", "liter", "liters"]
        }
    }
    
    private func parseNextSection() {
        sections.append(RecipeSection(header: nextSectionHeader, details: nextSectionDetails))
        nextSectionHeader = ""
        nextSectionDetails = ""
    }
    
    private func deleteIngredient(_ ingredient: Ingredient) {
        ingredients.removeAll { i in
            i == ingredient
        }
    }
    
    private func deleteSection(_ section: RecipeSection) {
        sections.removeAll { s in
            s == section
        }
    }
    
    private func save() {
        if !nextSectionDetails.isEmpty {
            sections.append(RecipeSection(header: nextSectionHeader, details: nextSectionDetails))
            nextSectionHeader = ""
            nextSectionDetails = ""
        }
        if let recipe = recipe {
            recipe.name = name
            recipe.metaData.details = details
            recipe.metaData.prepTime = prepTime
            recipe.metaData.cookTime = cookTime
            recipe.instructions = sections
            recipe.size.servingSize = servingSize
            recipe.size.numServings = numServings
            recipe.size.cookedAmount = cookedWeight > 0 ? FoodAmount.grams(cookedWeight) : nil
        } else {
            let recipe = Recipe(name: name,
                                metaData: RecipeMetaData(
                                    details: details,
                                    prepTime: prepTime,
                                    cookTime: cookTime,
                                    // TODO
                                    otherTime: 0,
                                    tags: []),
                                instructions: sections,
                                size: RecipeSize(totalAmount: FoodAmount.grams(0), cookedAmount: cookedWeight > 0 ? FoodAmount.grams(cookedWeight) : nil, numServings: numServings, servingSize: servingSize),
                                nutrients: [:])
            modelContext.insert(recipe)
            for ingredient in ingredients {
                recipe.ingredients.append(RecipeIngredient(name: ingredient.name, food: ingredient.food, recipe: recipe, amount: FoodAmount(value: ingredient.amount, unit: ingredient.unit)))
            }
        }
        dismiss()
    }
    
    private func discard() {
        dismiss()
    }
}

private struct Ingredient: Equatable, Hashable {
    var name: String
    var food: FoodItem?
    var amount: Double
    var unit: FoodUnit
    
    init(name: String, food: FoodItem? = nil, amount: Double, unit: FoodUnit) {
        self.name = name
        self.food = food
        self.amount = amount
        self.unit = unit
    }
}

#Preview {
    let container = createTestModelContainer()
    let recipe = createTestRecipeItem(container.mainContext)
    return NavigationStack {
        RecipeEditor(recipe: recipe)
            .modelContainer(container)
    }
}
