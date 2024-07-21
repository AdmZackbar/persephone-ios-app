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
                    }.swipeActions {
                        Button(role: .destructive) {
                            modelContext.delete(recipe)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        NavigationLink {
                            RecipeEditor(recipe: recipe)
                        } label: {
                            Label("Edit", systemImage: "pencil").tint(.blue)
                        }
                    }.contextMenu {
                        NavigationLink {
                            RecipeEditor(recipe: recipe)
                        } label: {
                            Label("Edit", systemImage: "pencil").tint(.blue)
                        }
                        Button(role: .destructive) {
                            modelContext.delete(recipe)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } preview: {
                        NavigationStack {
                            PreviewRecipe(recipe: recipe)
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
    
    private func isRecipeFiltered(recipe: Recipe) -> Bool {
        searchText.isEmpty || recipe.name.localizedCaseInsensitiveContains(searchText)
    }
}

private struct PreviewRecipe: View {
    var recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipe.name).font(.title).bold()
            Text(recipe.metaData.details).font(.subheadline).italic()
            Spacer()
        }.padding()
    }
    
    init(recipe: Recipe) {
        self.recipe = recipe
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
