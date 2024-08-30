//
//  RecipeView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/17/24.
//

import SwiftData
import SwiftUI

struct RecipeView: View {
    @StateObject var sheetCoordinator = SheetCoordinator<CookbookSheetEnum>()
    
    @State var recipe: Recipe
    @State private var nutrientViewType: NutrientViewType = .PerServing
    
    private enum NutrientViewType {
        case PerServing
        case Whole
    }
    
    let servingFormatter: NumberFormatter = {
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
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if recipe.metaData.author != nil {
                    Label(recipe.metaData.author!, systemImage: "person.fill").font(.subheadline).italic()
                }
                Text(recipe.metaData.details)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .italic()
                    .fontWeight(.light)
                    .font(.subheadline)
                ScrollView([.horizontal]) {
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
                    }
                }.scrollIndicators(.hidden)
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
                }
                skillRatingRow()
                Divider()
                if (!recipe.ingredients.isEmpty) {
                    ForEach(recipe.ingredients, id: \.name) { ingredient in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("\(ingredient.amount.value.toString()) \(ingredient.amount.unit.getAbbreviation())").bold()
                                Text("·")
                                Text(ingredient.name)
                            }
                            if !(ingredient.notes ?? "").isEmpty {
                                Text(ingredient.notes!).font(.caption)
                                    .fontWeight(.light)
                                    .italic()
                                    .lineLimit(2)
                            }
                        }.contextMenu {
                            Button {
                                sheetCoordinator.presentSheet(.EditIngredient(ingredient: ingredient))
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                        }
                    }
                    Divider()
                }
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recipe.instructions, id: \.self.header) { section in
                        if !section.header.isEmpty {
                            Text(section.header.uppercased()).font(.headline).fontWeight(.semibold).italic()
                        }
                        Text(section.details).font(.subheadline).fontWeight(.light)
                        Spacer()
                    }
                }
                if !recipe.nutrients.isEmpty {
                    Divider()
                    Picker("", selection: $nutrientViewType) {
                        Text("serving").tag(NutrientViewType.PerServing)
                        Text("recipe").tag(NutrientViewType.Whole)
                    }.pickerStyle(.segmented)
                    MacroChartView(nutrients: recipe.nutrients, scale: computeNutrientScale())
                        .frame(width: 180, height: 140)
                        .fixedSize(horizontal: true, vertical: true)
                    NutrientTableView(nutrients: recipe.nutrients, scale: computeNutrientScale())
                }
            }.padding(EdgeInsets(top: 8, leading: 20, bottom: 12, trailing: 20))
        }.navigationTitle(recipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .sheetCoordinating(coordinator: sheetCoordinator)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(recipe.name).font(.headline).bold()
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        RecipeEditor(recipe: recipe)
                    } label: {
                        Label("Edit", systemImage: "pencil.line").labelStyle(.titleOnly)
                    }
                }
            }
    }
    
    private func computeNutrientScale() -> Double {
        nutrientViewType == .PerServing ? 1 / recipe.size.numServings : 1
    }
    
    private func skillRatingRow() -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: computeImage(Recipe.DifficultyLevel.fromValue(value: recipe.metaData.difficulty) ?? .Trivial))
                createStackedText(upper: Recipe.DifficultyLevel.fromValue(value: recipe.metaData.difficulty)?.rawValue ?? "N/A", lower: "SKILL LEVEL")
            }.contextMenu {
                Button("N/A") {
                    recipe.metaData.difficulty = nil
                }
                ForEach(Recipe.DifficultyLevel.allCases) { level in
                    Button(level.rawValue) {
                        recipe.metaData.difficulty = level.getValue()
                    }
                }
            }
            Divider()
            HStack(spacing: 10) {
                Image(systemName: "leaf.fill")
                createStackedText(upper: "\(FoodTier.fromRating(rating: recipe.metaData.rating)?.rawValue ?? "N/A") tier", lower: "FRESH")
            }.contextMenu {
                Button("N/A") {
                    recipe.metaData.rating = nil
                }
                ForEach(FoodTier.allCases) { tier in
                    Button(tier.rawValue) {
                        recipe.metaData.rating = tier.getRating()
                    }
                }
            }
            Divider()
            HStack(spacing: 10) {
                Image(systemName: "snowflake")
                createStackedText(upper: "\(FoodTier.fromRating(rating: recipe.metaData.ratingLeftover)?.rawValue ?? "N/A") tier", lower: "LEFTOVER")
            }.contextMenu {
                Button("N/A") {
                    recipe.metaData.ratingLeftover = nil
                }
                ForEach(FoodTier.allCases) { tier in
                    Button(tier.rawValue) {
                        recipe.metaData.ratingLeftover = tier.getRating()
                    }
                }
            }
        }
    }
    
    private func computeImage(_ level: Recipe.DifficultyLevel) -> String {
        switch level {
        case .Trivial:
            "gauge.with.dots.needle.0percent"
        case .Easy:
            "gauge.with.dots.needle.33percent"
        case .Medium:
            "gauge.with.dots.needle.50percent"
        case .Hard:
            "gauge.with.dots.needle.67percent"
        case .Insane:
            "gauge.with.dots.needle.100percent"
        }
    }
    
    private func createStackedText(upper: String, lower: String) -> some View {
        VStack(alignment: .leading) {
            Text(upper).font(.subheadline).bold()
            Text(lower).font(.caption2).fontWeight(.light).italic()
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    let recipe = createTestRecipeItem(container.mainContext)
    return NavigationStack {
        RecipeView(recipe: recipe)
            .modelContainer(container)
    }
}
