//
//  RecipePreview.swift
//  Persephone
//
//  Created by Zach Wassynger on 9/2/24.
//

import SwiftUI

struct RecipePreview: View {
    let recipe: Recipe
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    let timeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                    .bold()
                if let author = recipe.metaData.author {
                    Label(author, systemImage: "person.fill")
                        .font(.subheadline)
                        .italic()
                }
                let tags = recipe.metaData.tags.joined(separator: ", ")
                if !tags.isEmpty {
                    Label(tags, systemImage: "tag.fill")
                        .font(.caption)
                        .bold()
                }
                HStack(spacing: 6) {
                    Label("\(formatter.string(for: recipe.size.numServings)!) servings", systemImage: "person.2.fill")
                        .font(.caption)
                    Text("·")
                    Text(recipe.size.servingSize)
                        .font(.caption)
                }
            }
            HStack(alignment: .top) {
                MacroChartView(nutrients: recipe.nutrients, scale: 1 / recipe.size.numServings)
                    .frame(width: 140, height: 100)
                Divider()
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("Total:")
                            .font(.subheadline)
                            .italic()
                        Spacer()
                        Text(formatTime(recipe.metaData.totalTime))
                            .font(.subheadline)
                            .bold()
                    }
                    HStack(spacing: 8) {
                        Text("Prep:")
                            .font(.subheadline)
                            .italic()
                        Spacer()
                        Text(formatTime(recipe.metaData.prepTime))
                            .font(.subheadline)
                            .bold()
                    }
                    HStack(spacing: 8) {
                        Text("Cook:")
                            .font(.subheadline)
                            .italic()
                        Spacer()
                        Text(formatTime(recipe.metaData.cookTime))
                            .font(.subheadline)
                            .bold()
                    }
                }
            }
        }.padding()
    }
    
    func formatTime(_ time: Double) -> String {
        "\(timeFormatter.string(for: time)!) min"
    }
}

#Preview {
    let container = createTestModelContainer()
    let recipe = createTestRecipeItem(container.mainContext)
    return Form {
        Text(recipe.name).contextMenu {
            Button("test") {
                
            }
        } preview: {
            RecipePreview(recipe: recipe)
        }
    }
}
