//
//  RecipeView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/17/24.
//

import SwiftData
import SwiftUI

struct RecipeView: View {
    var recipe: Recipe
    
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
                Divider()
                if (!recipe.ingredients.isEmpty) {
                    ForEach(recipe.ingredients, id: \.name) { ingredient in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("\(servingFormatter.string(for: ingredient.amount.value)!) \(ingredient.amount.unit.getAbbreviation())").bold()
                                Text("·")
                                Text(ingredient.name)
                            }
                            if !(ingredient.notes ?? "").isEmpty {
                                Text(ingredient.notes!).font(.caption)
                                    .fontWeight(.light)
                                    .italic()
                                    .lineLimit(2)
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
                    NutrientView(recipe: recipe, nutrients: recipe.nutrients)
                }
            }.padding(EdgeInsets(top: 8, leading: 20, bottom: 12, trailing: 20))
        }.navigationTitle(recipe.name)
            .navigationBarTitleDisplayMode(.inline)
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
    
    private func createStackedText(upper: String, lower: String) -> some View {
        VStack(alignment: .leading) {
            Text(upper).font(.subheadline).bold()
            Text(lower).font(.caption2).fontWeight(.light).italic()
        }
    }
}

private struct NutrientView: View {
    @State private var viewType: ViewType = .PerServing
    
    let recipe: Recipe
    let nutrients: [Nutrient : FoodAmount]
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 10) {
            Picker("", selection: $viewType) {
                Text(recipe.size.servingSize.capitalized).tag(ViewType.PerServing)
                Text("\(formatter.string(for: recipe.size.numServings)!) Servings").tag(ViewType.WholeAmount)
            }.pickerStyle(.segmented)
            createNutrientRow(name: "Calories", nutrient: .Energy).font(.title3).fontWeight(.semibold)
            Divider()
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
        }.font(.subheadline).padding().overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.secondary)
        )
    }
    
    private func createNutrientRow(name: String, nutrient: Nutrient) -> some View {
        HStack {
            Text(name)
            Spacer()
            if nutrient == .Energy {
                Text(formatter.string(for: modifyAmountIfNeeded(nutrients[.Energy]?.value))!)
            } else {
                Text("\(formatter.string(for: modifyAmountIfNeeded(nutrients[nutrient]?.value))!) \(nutrient.getCommonUnit().getAbbreviation())")
            }
        }
    }
    
    private func modifyAmountIfNeeded(_ value: Double?) -> Double {
        if value == nil {
            return 0
        }
        switch viewType {
        case .PerServing:
            return value!
        case .WholeAmount:
            return value! * recipe.size.numServings
        }
    }
    
    enum ViewType: Identifiable {
        var id: Int {
            get {
                self.hashValue
            }
        }
        
        case PerServing, WholeAmount
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
