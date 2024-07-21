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
                TextEditor(text: $details).frame(height: 100).textInputAutocapitalization(.sentences)
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
                            if (prepTime > 0.0) {
                                Text("min").italic()
                            }
                        }.frame(minWidth: 100)
                        Divider().padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                        HStack {
                            Text("Cook:")
                            TextField("minutes", value: $cookTime, formatter: durationFormatter)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                            if (cookTime > 0.0) {
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
            Section("Instructions") {
                List(sections, id: \.self.header) { section in
                    DisclosureGroup {
                        Text(section.steps.joined(separator: "\n")).font(.subheadline).fontWeight(.thin)
                    } label: {
                        Text(section.header ?? "Untitled").bold()
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
                    ingredients = recipe.foodEntries.map({ entry in
                        Ingredient(name: entry.name, food: entry.food, amount: entry.amount, unit: entry.unit)
                    })
                    sections = recipe.metaData.instructions.sections
                    prepTime = recipe.metaData.prepTime
                    cookTime = recipe.metaData.cookTime
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
            for unitName in foodUnit.getNames() {
                if unit.caseInsensitiveCompare(unitName) == .orderedSame {
                    return foodUnit
                }
            }
        }
        return nil
    }
    
    private func parseNextSection() {
        sections.append(RecipeSection(header: nextSectionHeader.isEmpty ? nil : nextSectionHeader, steps: nextSectionDetails.split(separator: "\n").map({ str in
            str.string
        })))
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
            sections.append(RecipeSection(header: nextSectionHeader, steps: nextSectionDetails.split(separator: "\n").map({ s in s.string })))
            nextSectionHeader = ""
            nextSectionDetails = ""
        }
        if let recipe = recipe {
            recipe.name = name
            recipe.metaData.details = details
            recipe.metaData.prepTime = prepTime
            recipe.metaData.cookTime = cookTime
            recipe.metaData.instructions.sections = sections
        } else {
            // TODO
            let recipe = Recipe(name: name,
                                sizeInfo: RecipeSizeInfo(servingSize: "", numServings: 0, cookedWeight: 0),
                                metaData: RecipeMetaData(
                                    details: details,
                                    instructions: RecipeInstructions(sections: sections),
                                    prepTime: prepTime,
                                    cookTime: cookTime,
                                    tags: []))
            modelContext.insert(recipe)
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Recipe.self, configurations: config)
    let recipe = Recipe(name: "Buttermilk Waffles",
                        sizeInfo: RecipeSizeInfo(
                            servingSize: "1 waffle",
                            numServings: 6,
                            cookedWeight: 255),
                        metaData: RecipeMetaData(
                            details: "My fav waffles, some more text here just put them on the iron for a few minutes and eat",
                            instructions: RecipeInstructions(sections: [
                                RecipeSection(header: "Prep", steps: [
                                    "1. Put the mix with the water",
                                    "2. Mix until barely combined"
                                ]), RecipeSection(header: "Cook", steps: [
                                    "1. Put mix into the iron",
                                    "2. Wait until iron signals completion",
                                    "3. Remove and allow to cool"
                                ])
                            ]),
                            prepTime: 8,
                            cookTime: 17,
                            tags: ["Breakfast", "Bread"]),
                        composition: FoodComposition(nutrients: [
                            .Energy: 200,
                            .TotalFat: 4.1,
                            .SaturatedFat: 2,
                            .TotalCarbs: 20,
                            .DietaryFiber: 1,
                            .TotalSugars: 3,
                            .Protein: 13.5
                        ]))
    container.mainContext.insert(recipe)
    container.mainContext.insert(RecipeFoodEntry(name: "Water", recipe: recipe, amount: 1.0, unit: .Liter))
    container.mainContext.insert(RecipeFoodEntry(name: "Salt", recipe: recipe, amount: 600, unit: .Milligram))
    return NavigationStack {
        RecipeEditor(recipe: recipe)
            .modelContainer(container)
    }
}
