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
                        RecipePreview(recipe: recipe)
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
        let duplicateRecipe = Recipe(name: recipe.name, metaData: recipe.metaData, instructions: recipe.instructions, size: recipe.size)
        modelContext.insert(duplicateRecipe)
        for ingredient in recipe.ingredients {
            let duplicateEntry = RecipeIngredient(name: ingredient.name, food: ingredient.food, recipe: duplicateRecipe, amount: ingredient.amount)
            modelContext.insert(duplicateEntry)
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
    let container = createTestModelContainer()
    createTestRecipeItem(container.mainContext)
    createTestFoodItem(container.mainContext)
    return CookbookView()
        .modelContainer(container)
}
