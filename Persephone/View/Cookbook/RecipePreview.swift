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
                NutrientPieChart(nutrients: recipe.nutrients, scale: 1 / recipe.size.numServings)
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

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    Form {
        Text("test").contextMenu {
            Button("test") {
                
            }
        } preview: {
            RecipePreview(recipe: .init(
                name: "Test Recipe",
                metaData: Recipe.MetaData(
                    author: "Zach Wassynger",
                    details: "My fav waffles, some more text here just put them on the iron for a few minutes and eat",
                    prepTime: 8,
                    cookTime: 17,
                    otherTime: 0,
                    tags: ["Breakfast", "Bread"],
                    rating: 7.5,
                    ratingLeftover: 5,
                    difficulty: 5),
                instructions: [
                    Recipe.Section(header: "Prep", details: "1. Put the mix with the water\n2. Mix until barely combined"),
                    Recipe.Section(header: "Cook", details: "1. Put mix into the iron\n2. Wait until iron signals completion\n3. Remove and allow to cool")],
                size: Recipe.Size(
                    numServings: 6,
                    servingSize: "1 waffle"
                ),
                ingredients: [
                    .init(name: "Water", amount: Quantity(value: .Raw(1.2), unit: .Liter), notes: "Tap water or else"),
                    .init(name: "Salt", amount: Quantity(value: .Raw(600), unit: .Milligram)),
                ]))
        }
    }
}
