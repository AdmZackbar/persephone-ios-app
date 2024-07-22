//
//  CookbookView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/16/24.
//

import SwiftData
import SwiftUI

struct CookbookView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Recipe.name) var recipes: [Recipe]
    
    @State private var searchText = ""
    @State private var showDuplicateDialog = false
    @State private var duplicateName = ""
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.zeroSymbol = ""
        return formatter
    }()
    
    var body: some View {
        let filteredRecipes = recipes.filter(isRecipeFiltered)
        return NavigationStack {
            List(filteredRecipes) { recipe in
                NavigationLink {
                    RecipeView(recipe: recipe)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(recipe.name)
                        HStack(spacing: 12) {
                            Label(recipe.metaData.tags.joined(separator: ", "), systemImage: "tag.fill").font(.caption).fontWeight(.semibold).labelStyle(CustomTagLabel())
                            Label("\(formatter.string(for: recipe.metaData.totalTime)!) min", systemImage: "clock.fill").font(.caption).fontWeight(.semibold).labelStyle(CustomTagLabel())
                        }
                    }.swipeActions(allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            modelContext.delete(recipe)
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                        Button {
                            showDuplicateRecipe(recipe)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc.fill").tint(.teal)
                        }
                        NavigationLink {
                            RecipeEditor(recipe: recipe)
                        } label: {
                            Label("Edit", systemImage: "pencil").tint(.blue)
                        }
                    }.contextMenu {
                        NavigationLink {
                            RecipeView(recipe: recipe)
                        } label: {
                            Label("View", systemImage: "magnifyingglass")
                        }
                        NavigationLink {
                            RecipeEditor(recipe: recipe)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button {
                            showDuplicateRecipe(recipe)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc.fill")
                        }
                        Button(role: .destructive) {
                            modelContext.delete(recipe)
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    } preview: {
                        NavigationStack {
                            PreviewRecipe(recipe: recipe)
                        }
                    }
                    .alert("Duplicate Recipe", isPresented: $showDuplicateDialog) {
                        TextField("Name", text: $duplicateName)
                        Button("OK") {
                            duplicateRecipe(recipe)
                        }
                        Button("Cancel") {
                            showDuplicateDialog = false
                            duplicateName = ""
                        }
                    }
                }
            }
            .overlay(Group {
                if (filteredRecipes.isEmpty) {
                    Text(recipes.isEmpty ? "No recipes in database." : "No recipes found.")
                }
            })
            .navigationTitle("Cookbook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    NavigationLink {
                        RecipeEditor()
                    } label: {
                        Label("Create Recipe", systemImage: "plus")
                    }
                }
            }
        }.searchable(text: $searchText, prompt: "Filter...")
    }
    
    private func isRecipeFiltered(_ recipe: Recipe) -> Bool {
        searchText.isEmpty || recipe.name.localizedCaseInsensitiveContains(searchText)
    }
    
    private func showDuplicateRecipe(_ recipe: Recipe) {
        let mark = /[mM][kK]\.?\s*(\d+)/
        var updatedName: String? = nil
        if let match = recipe.name.firstMatch(of: mark) {
            let num = Int(match.1)!
            updatedName = "\(recipe.name[..<match.range.lowerBound])Mk. \(num + 1)"
        } else {
            updatedName = "\(recipe.name) Mk. 2"
        }
        duplicateName = updatedName!
        showDuplicateDialog = true
    }
    
    private func duplicateRecipe(_ recipe: Recipe) {
        let duplicateRecipe = Recipe(name: duplicateName, sizeInfo: recipe.sizeInfo, metaData: recipe.metaData, composition: recipe.composition)
        modelContext.insert(duplicateRecipe)
        for entry in recipe.foodEntries {
            let duplicateEntry = RecipeFoodEntry(name: entry.name, food: entry.food, recipe: duplicateRecipe, amount: entry.amount, unit: entry.unit)
            modelContext.insert(duplicateEntry)
        }
    }
}

private struct PreviewRecipe: View {
    var recipe: Recipe
    
    let servingFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    let timeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(recipe.name).font(.title).bold()
            Text(recipe.metaData.details).font(.subheadline).italic()
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "person.2.fill")
                    createStackedText(upper: "\(servingFormatter.string(for: recipe.sizeInfo.numServings)!) servings", lower: recipe.sizeInfo.servingSize.uppercased())
                }
                if !recipe.metaData.tags.isEmpty {
                    Divider()
                    Label(recipe.metaData.tags.joined(separator: ", "), systemImage: "tag.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }.fixedSize(horizontal: false, vertical: true).scrollIndicators(.hidden)
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "clock.fill")
                    createStackedText(upper: "\(timeFormatter.string(for: recipe.metaData.totalTime)!) min", lower: "TOTAL")
                }
                Divider()
                createStackedText(upper: "\(timeFormatter.string(for: recipe.metaData.prepTime)!) min", lower: "PREP")
                Divider()
                createStackedText(upper: "\(timeFormatter.string(for: recipe.metaData.cookTime)!) min", lower: "COOK")
                Spacer()
            }.fixedSize(horizontal: false, vertical: true)
            if (recipe.composition != nil) {
                Divider()
                NutrientView(recipe: recipe, nutrients: recipe.composition!.nutrients)
            }
            Spacer()
        }.padding()
    }
    
    private func createStackedText(upper: String, lower: String) -> some View {
        VStack(alignment: .leading) {
            Text(upper).font(.subheadline).bold()
            Text(lower).font(.caption2).fontWeight(.light).italic()
        }
    }
    
    init(recipe: Recipe) {
        self.recipe = recipe
    }
}

private struct NutrientView: View {
    let recipe: Recipe
    let nutrients: [Nutrient : Double]
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Per Serving:").font(.headline).bold()
            createNutrientRow(name: "Calories", nutrient: .Energy).fontWeight(.semibold)
            createNutrientRow(name: "Total Fat", nutrient: .TotalFat)
            if nutrients[.SaturatedFat] != nil {
                createNutrientRow(name: "Saturated Fat", nutrient: .SaturatedFat).padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0)).italic()
            }
            if nutrients[.TransFat] != nil {
                createNutrientRow(name: "Trans Fat", nutrient: .TransFat).padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0)).italic()
            }
            createNutrientRow(name: "Total Carbohydrates", nutrient: .TotalCarbs)
            if nutrients[.DietaryFiber] != nil {
                createNutrientRow(name: "Dietary Fiber", nutrient: .DietaryFiber).padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0)).italic()
            }
            if nutrients[.TotalSugars] != nil {
                createNutrientRow(name: "Total Sugars", nutrient: .TotalSugars).padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0)).italic()
            }
            if nutrients[.AddedSugars] != nil {
                createNutrientRow(name: "Added Sugars", nutrient: .AddedSugars).padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0)).italic()
            }
            createNutrientRow(name: "Cholesterol", nutrient: .Cholesterol)
            createNutrientRow(name: "Sodium", nutrient: .Sodium)
            createNutrientRow(name: "Protein", nutrient: .Protein)
        }.font(.subheadline)
    }
    
    private func createNutrientRow(name: String, nutrient: Nutrient) -> some View {
        HStack {
            Text(name)
            Spacer()
            if nutrient == .Energy {
                Text(formatter.string(for: nutrients[.Energy] ?? 0)!)
            } else {
                Text("\(formatter.string(for: nutrients[nutrient] ?? 0)!) \(nutrient.getUnit())")
            }
        }
    }
}

private struct CustomTagLabel: LabelStyle {
    var spacing: Double = 4.0
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: spacing) {
            configuration.icon
            configuration.title
        }
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
    return CookbookView()
        .modelContainer(container)
}
