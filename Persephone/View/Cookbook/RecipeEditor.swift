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
    
    private enum Mode {
        case Add, Edit
        
        func computeTitle() -> String {
            switch self {
            case .Add:
                "Create Recipe"
            case .Edit:
                "Edit Recipe"
            }
        }
    }
    
    private var mode: Mode
    private var recipe: Recipe
    private var ingredientsBackup: [RecipeIngredient]
    
    init(recipe: Recipe? = nil) {
        self.mode = recipe == nil ? .Add : .Edit
        self.recipe = recipe ?? Recipe(name: "", metaData: Recipe.MetaData(details: "", prepTime: 0, cookTime: 0, otherTime: 0, tags: []), instructions: [], size: Recipe.Size(numServings: 1, servingSize: ""))
        self.ingredientsBackup = recipe?.ingredients ?? []
    }
    
    @State private var name: String = ""
    @State private var author: String = ""
    @State private var details: String = ""
    @State private var tags: [String] = []
    @State private var rating: Double? = nil
    @State private var ratingLeftover: Double? = nil
    @State private var difficulty: Double? = nil
    @State private var servingSize: String = ""
    @State private var numServings: Double = 1
    @State private var cookTime: Double = 0
    @State private var prepTime: Double = 0
    @State private var otherTime: Double = 0
    private var totalTime: Double {
        cookTime + prepTime + otherTime
    }
    @State private var instructions: [Recipe.Section] = []
    
    private let timeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        return formatter
    }()
    
    var body: some View {
        Form {
            Section("Description") {
                HStack {
                    Text("Name:")
                    TextField("required", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                HStack {
                    Text("Author:")
                    TextField("optional", text: $author)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
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
                TextField("description", text: $details, axis: .vertical)
                    .textInputAutocapitalization(.sentences).lineLimit(3...10)
            }
            if mode == .Edit {
                ingredientsSection()
            }
            instructionsSection()
            Section("Size") {
                HStack {
                    Text("Serving Size:")
                    TextField("required", text: $servingSize)
                        .autocorrectionDisabled()
                }
                Stepper {
                    HStack {
                        Text("Num. Servings:").fixedSize()
                        TextField("", value: $numServings, formatter: timeFormatter)
                            .multilineTextAlignment(.trailing).italic()
                            .keyboardType(.decimalPad)
                    }
                } onIncrement: {
                    numServings += 1
                } onDecrement: {
                    if numServings > 1 {
                        numServings -= 1
                    }
                }
            }
            timesSection()
            Section("Rating") {
                Picker("Rating (Fresh):", selection: $rating) {
                    Text("N/A").tag(nil as Double?)
                    ForEach(RatingTier.allCases) { tier in
                        Text(tier.rawValue).tag(tier.rating as Double?)
                    }
                }
                Picker("Rating (Leftover):", selection: $ratingLeftover) {
                    Text("N/A").tag(nil as Double?)
                    ForEach(RatingTier.allCases) { tier in
                        Text(tier.rawValue).tag(tier.rating as Double?)
                    }
                }
                Picker("Skill Level:", selection: $difficulty) {
                    Text("N/A").tag(nil as Double?)
                    ForEach(Recipe.DifficultyLevel.allCases) { difficulty in
                        Text(difficulty.rawValue).tag(difficulty.getValue() as Double?)
                    }
                }
            }
        }.navigationTitle(mode.computeTitle())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .sheetCoordinating(coordinator: sheetCoordinator)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Save", action: save).disabled(name.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(mode == .Add ? "Discard" : "Cancel", action: discard)
                }
            }
            .onAppear {
                if mode == .Edit {
                    name = recipe.name
                    author = recipe.metaData.author ?? ""
                    details = recipe.metaData.details
                    tags = recipe.metaData.tags
                    rating = recipe.metaData.rating
                    ratingLeftover = recipe.metaData.ratingLeftover
                    difficulty = recipe.metaData.difficulty
                    servingSize = recipe.size.servingSize
                    numServings = recipe.size.numServings
                    prepTime = recipe.metaData.prepTime
                    cookTime = recipe.metaData.cookTime
                    otherTime = recipe.metaData.otherTime
                    instructions = recipe.instructions
                }
            }
    }
    
    private func ingredientsSection() -> some View {
        Section("Ingredients") {
            List(recipe.ingredients, id: \.name) { ingredient in
                Button {
                    editIngredient(ingredient)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(ingredient.amountToString()) · \(ingredient.name)")
                            if !(ingredient.notes ?? "").isEmpty {
                                Text(ingredient.notes!).font(.caption).italic()
                            }
                        }
                        Spacer()
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .swipeActions(allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            recipe.ingredients.removeAll { i in i == ingredient }
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                        Button {
                            editIngredient(ingredient)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                    .contextMenu {
                        Button {
                            editIngredient(ingredient)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            recipe.ingredients.removeAll { i in i == ingredient }
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    } preview: {
                        if let foodItem = ingredient.food {
                            FoodItemPreview(item: foodItem)
                        } else {
                            Text(ingredient.name).padding()
                        }
                    }
            }
            Menu {
                Button("Food Item Ingredient...") {
                    sheetCoordinator.presentSheet(.AddItemIngredient(recipe: recipe))
                }
                Button("Custom Ingredient...") {
                    sheetCoordinator.presentSheet(.AddIngredient(recipe: recipe))
                }
            } label: {
                Label("Add Ingredient...", systemImage: "plus")
            }
        }
    }
    
    private func instructionsSection() -> some View {
        Section("Instructions") {
            List(instructions, id: \.header) { section in
                Button {
                    sheetCoordinator.presentSheet(.EditInstructions(section: section))
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(section.header).font(.headline)
                            Text(section.details).lineLimit(3).font(.caption)
                        }
                        Spacer()
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .swipeActions(allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            instructions.removeAll { s in s == section }
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                        Button {
                            sheetCoordinator.presentSheet(.EditInstructions(section: section))
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
            }
            Button {
                sheetCoordinator.presentSheet(.AddInstructions(instructions: $instructions))
            } label: {
                Label("Add Section...", systemImage: "plus")
            }
        }
    }
    
    private func timesSection() -> some View {
        Section("Times") {
            Stepper {
                HStack {
                    Text("Prep Time:").fixedSize()
                    TextField("", value: $prepTime, formatter: timeFormatter)
                        .multilineTextAlignment(.trailing).italic()
                        .keyboardType(.decimalPad)
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
                        .keyboardType(.decimalPad)
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
                        .keyboardType(.decimalPad)
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
    }
    
    private func editIngredient(_ ingredient: RecipeIngredient) {
        sheetCoordinator.presentSheet(.EditIngredient(ingredient: ingredient))
    }
    
    private func save() {
        recipe.name = name
        recipe.metaData.author = author.isEmpty ? nil : author
        recipe.metaData.details = details
        recipe.metaData.tags = tags
        recipe.metaData.rating = rating
        recipe.metaData.ratingLeftover = ratingLeftover
        recipe.metaData.difficulty = difficulty
        recipe.size.servingSize = servingSize
        recipe.size.numServings = numServings
        recipe.metaData.prepTime = prepTime
        recipe.metaData.cookTime = cookTime
        recipe.metaData.otherTime = otherTime
        recipe.instructions = instructions
        if mode == .Add {
            modelContext.insert(recipe)
        }
        dismiss()
    }
    
    private func discard() {
        if mode == .Edit {
            recipe.ingredients = ingredientsBackup
        }
        dismiss()
    }
}

#Preview {
    let container = createTestModelContainer()
    let recipe = createTestRecipeItem(container.mainContext)
    createTestFoodItem(container.mainContext)
    return NavigationStack {
        RecipeEditor(recipe: recipe)
            .modelContainer(container)
    }
}
