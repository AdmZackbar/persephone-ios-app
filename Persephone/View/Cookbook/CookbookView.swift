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
        let duplicateRecipe = Recipe(name: recipe.name, metaData: recipe.metaData, instructions: recipe.instructions, size: recipe.size)
        modelContext.insert(duplicateRecipe)
        for ingredient in recipe.ingredients {
            let duplicateEntry = RecipeIngredient(name: ingredient.name, food: ingredient.food, recipe: duplicateRecipe, amount: ingredient.amount)
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
                    createStackedText(upper: "\(servingFormatter.string(for: recipe.size.numServings)!) servings", lower: recipe.size.servingSize.uppercased())
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
