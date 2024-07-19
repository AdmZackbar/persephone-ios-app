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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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
                            .labelStyle(CenterLabelStyle())
                    }
                }
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.fill")
                        createStackedText(upper: "\(timeFormatter.string(for: recipe.metaData.totalTime)!) min", lower: "TOTAL")
                    }
                    Divider()
                    createStackedText(upper: "\(timeFormatter.string(for: recipe.metaData.prepTime)!) min", lower: "PREP")
                    if recipe.metaData.cookTime != nil {
                        Divider()
                        createStackedText(upper: "\(timeFormatter.string(for: recipe.metaData.cookTime!)!) min", lower: "COOK")
                    }
                    Spacer()
                }
                Text(recipe.metaData.details)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                    .italic()
                    .fontWeight(.light)
                    .font(.subheadline)
                Divider()
                if (!recipe.foodEntries.isEmpty) {
                    ForEach(recipe.foodEntries.sorted(by: { x, y in
                        x.name.caseInsensitiveCompare(y.name).rawValue < 0
                    }), id: \.name) { entry in
                        HStack(spacing: 8) {
                            Text("\(servingFormatter.string(for: entry.amount)!) \(entry.unit.getAbbreviation())").bold()
                            Text("·")
                            Text(entry.name).fontWeight(.light)
                        }
                    }
                    Divider()
                }
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recipe.metaData.instructions.sections, id: \.self.header) { section in
                        if section.header != nil {
                            Text(section.header!.uppercased()).font(.headline).fontWeight(.semibold).italic()
                        }
                        ForEach(section.steps, id: \.self) { step in
                            Text(step).font(.subheadline).fontWeight(.light)
                        }
                        Spacer()
                    }
                }
                if recipe.composition != nil {
                    NutrientView(recipe: recipe, nutrients: recipe.composition!.nutrients)
                }
            }.padding(24)
        }.navigationTitle(recipe.name)
            .toolbar {
                ToolbarItem(placement: .secondaryAction) {
                    NavigationLink {
                        RecipeEditor(recipe: recipe)
                    } label: {
                        Label("Edit", systemImage: "pencil")
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
    let nutrients: [Nutrient : Double]
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 10) {
            Picker("", selection: $viewType) {
                Text(recipe.sizeInfo.servingSize.capitalized).tag(ViewType.PerServing)
                Text("\(formatter.string(for: recipe.sizeInfo.numServings)!) Servings").tag(ViewType.WholeAmount)
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
                Text(formatter.string(for: modifyAmountIfNeeded(nutrients[.Energy]))!)
            } else {
                Text("\(formatter.string(for: modifyAmountIfNeeded(nutrients[nutrient]))!) \(nutrient.getUnit())")
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
            return value! * recipe.sizeInfo.numServings
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

private struct CenterLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center) {
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
                            totalTime: 25,
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
    return NavigationStack {
        RecipeView(recipe: recipe)
    }
}
