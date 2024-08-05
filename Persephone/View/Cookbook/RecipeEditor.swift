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
    
    @StateObject var sheetCoordinator = SheetCoordinator<CookbookSheetEnum>()
    
    var recipe: Recipe?
    
    @State private var name: String = ""
    @State private var details: String = ""
    @State private var tags: [String] = []
    @State private var servingSize: String = ""
    @State private var numServings: Double = 1
    @State private var cookTime: Double = 0
    @State private var prepTime: Double = 0
    @State private var otherTime: Double = 0
    private var totalTime: Double {
        cookTime + prepTime + otherTime
    }
    @State private var ingredients: [RecipeIngredient] = []
    
    private let timeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        return formatter
    }()
    
    var body: some View {
        Form {
            HStack {
                Text("Name:")
                TextField("required", text: $name).textInputAutocapitalization(.words)
            }
            HStack(alignment: .top) {
                Text("Tags:")
                if tags.isEmpty {
                    Text("None").italic().fontWeight(.light)
                }
                else {
                    Text(tags.joined(separator: ", "))
                }
                Spacer()
                Button("Edit") {
                    sheetCoordinator.presentSheet(.Tags(tags: $tags))
                }
            }
            HStack {
                Text("Serving Size:")
                TextField("required", text: $servingSize)
            }
            Stepper {
                HStack {
                    Text("Est. Num. Servings:").fixedSize()
                    TextField("", value: $numServings, formatter: timeFormatter)
                        .multilineTextAlignment(.trailing).italic()
                }
            } onIncrement: {
                numServings += 1
            } onDecrement: {
                if numServings > 1 {
                    numServings -= 1
                }
            }
            Section("Description") {
                TextField("optional", text: $details, axis: .vertical).textInputAutocapitalization(.sentences).lineLimit(3...5)
            }
            Section("Times") {
                Stepper {
                    HStack {
                        Text("Prep Time:").fixedSize()
                        TextField("", value: $prepTime, formatter: timeFormatter)
                            .multilineTextAlignment(.trailing).italic()
                        Text("min").italic()
                    }
                } onIncrement: {
                    prepTime += 1
                } onDecrement: {
                    if prepTime > 0 {
                        prepTime -= 1
                    }
                }
                Stepper {
                    HStack {
                        Text("Cook Time:").fixedSize()
                        TextField("", value: $cookTime, formatter: timeFormatter)
                            .multilineTextAlignment(.trailing).italic()
                        Text("min").italic()
                    }
                } onIncrement: {
                    cookTime += 1
                } onDecrement: {
                    if cookTime > 0 {
                        cookTime -= 1
                    }
                }
                Stepper {
                    HStack {
                        Text("Other:").fixedSize()
                        TextField("", value: $otherTime, formatter: timeFormatter)
                            .multilineTextAlignment(.trailing).italic()
                        Text("min").italic()
                    }
                } onIncrement: {
                    otherTime += 1
                } onDecrement: {
                    if otherTime > 0 {
                        otherTime -= 1
                    }
                }
                HStack {
                    Text("Total Time:")
                    Spacer()
                    Text("\(timeFormatter.string(for: totalTime)!) min").italic()
                }
            }
            Section("Ingredients") {
                List(ingredients, id: \.name) { ingredient in
                    Text("\(timeFormatter.string(for: ingredient.amount.value)!) \(ingredient.amount.unit.getAbbreviation()) of \(ingredient.name)")
                        .onTapGesture {
                            sheetCoordinator.presentSheet(.Ingredients(ingredient: ingredient))
                        }
                }
                Button {
                    sheetCoordinator.presentSheet(.Ingredients(ingredient: nil))
                } label: {
                    Label("Add Ingredient", systemImage: "plus")
                }
            }
        }.navigationTitle(recipe != nil ? "Edit Recipe" : "Create Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .sheetCoordinating(coordinator: sheetCoordinator)
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
                    tags = recipe.metaData.tags
                    servingSize = recipe.size.servingSize
                    numServings = recipe.size.numServings
                    prepTime = recipe.metaData.prepTime
                    cookTime = recipe.metaData.cookTime
                    otherTime = recipe.metaData.otherTime
                    ingredients = recipe.ingredients
                }
            }
    }
    
    private func save() {
        if let recipe = recipe {
            recipe.name = name
            recipe.metaData.details = details
        } else {
            // TODO
//            let recipe = Recipe(name: name,
//                                metaData: RecipeMetaData(
//                                    details: details,
//                                    prepTime: prepTime,
//                                    cookTime: cookTime,
//                                    // TODO
//                                    otherTime: 0,
//                                    tags: []),
//                                instructions: sections,
//                                size: RecipeSize(totalAmount: FoodAmount.grams(0), cookedAmount: cookedWeight > 0 ? FoodAmount.grams(cookedWeight) : nil, numServings: numServings, servingSize: servingSize),
//                                nutrients: [:])
//            modelContext.insert(recipe)
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
