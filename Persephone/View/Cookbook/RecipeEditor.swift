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
        self.recipe = recipe ?? Recipe(name: "", metaData: Recipe.MetaData(details: "", prepTime: 0, cookTime: 0, otherTime: 0, tags: []), instructions: [], size: Recipe.Size(numServings: 1, servingSize: ""), nutrients: [:])
        self.ingredientsBackup = recipe?.ingredients ?? []
    }
    
    @State private var name: String = ""
    @State private var author: String = ""
    @State private var details: String = ""
    @State private var tags: [String] = []
    @State private var rating: Double? = nil
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
            HStack {
                Picker("Rating:", selection: $rating) {
                    Text("N/A").tag(nil as Double?)
                    Text("S").tag(9.5 as Double?)
                    Text("A").tag(8 as Double?)
                    Text("B").tag(6.5 as Double?)
                    Text("C").tag(5 as Double?)
                    Text("D").tag(3.5 as Double?)
                    Text("F").tag(1 as Double?)
                }
                Divider()
                Picker("Skill:", selection: $difficulty) {
                    Text("N/A").tag(nil as Double?)
                    Text("Trivial").tag(1 as Double?)
                    Text("Easy").tag(3 as Double?)
                    Text("Medium").tag(5 as Double?)
                    Text("Hard").tag(7 as Double?)
                    Text("Insane").tag(9 as Double?)
                }
            }
            Section("Description") {
                TextField("optional", text: $details, axis: .vertical).textInputAutocapitalization(.sentences).lineLimit(3...10)
            }
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
            Section("Ingredients") {
                List(recipe.ingredients, id: \.name) { ingredient in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(timeFormatter.string(for: ingredient.amount.value)!) \(ingredient.amount.unit.getAbbreviation()) · \(ingredient.name)")
                        if !(ingredient.notes ?? "").isEmpty {
                            Text(ingredient.notes!).font(.caption).italic()
                        }
                    }.onTapGesture {
                        sheetCoordinator.presentSheet(.EditIngredient(ingredient: ingredient))
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
        }.navigationTitle(mode.computeTitle())
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
                if mode == .Edit {
                    name = recipe.name
                    author = recipe.metaData.author ?? ""
                    details = recipe.metaData.details
                    tags = recipe.metaData.tags
                    servingSize = recipe.size.servingSize
                    numServings = recipe.size.numServings
                    prepTime = recipe.metaData.prepTime
                    cookTime = recipe.metaData.cookTime
                    otherTime = recipe.metaData.otherTime
                    instructions = recipe.instructions
                }
            }
    }
    
    private func save() {
        recipe.name = name
        recipe.metaData.author = author.isEmpty ? nil : author
        recipe.metaData.details = details
        recipe.metaData.tags = tags
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
        recipe.ingredients = ingredientsBackup
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
