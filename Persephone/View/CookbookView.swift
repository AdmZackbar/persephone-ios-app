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
    
    var body: some View {
        let filteredRecipes = recipes.filter(isRecipeFiltered)
        return NavigationStack {
            List(filteredRecipes) { recipe in
                NavigationLink {
                    Text("Recipe details here")
                } label: {
                    Text(recipe.name)
                }
            }
            .overlay(Group {
                if (filteredRecipes.isEmpty) {
                    Text("No recipes in database.")
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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Recipe.self, configurations: config)
    return CookbookView()
        .modelContainer(container)
}
