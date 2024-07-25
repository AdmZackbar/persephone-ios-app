//
//  PreviewHelpers.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/23/24.
//

import Foundation
import SwiftData

func createTestModelContainer() -> ModelContainer {
    let schema = Schema(CurrentSchema.models)
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    return container
}

@discardableResult
func createTestFoodItem(_ context: ModelContext) -> FoodItem {
    let item = FoodItem(name: "Test Food",
                        metaData: FoodMetaData(tags: ["Bread"]),
                        ingredients: FoodIngredients(
                            nutrients: [
                                .Energy: FoodAmount.calories(120),
                                .TotalFat: FoodAmount.grams(3.5),
                                .SaturatedFat: FoodAmount.grams(2),
                                .PolyunsaturatedFat: FoodAmount.grams(0.5),
                                .Cholesterol: FoodAmount.milligrams(50),
                                .Sodium: FoodAmount.milligrams(255),
                                .TotalCarbs: FoodAmount.grams(12),
                                .DietaryFiber: FoodAmount.grams(1),
                                .TotalSugars: FoodAmount.grams(0.5),
                                .Protein: FoodAmount.grams(5),
                                .Calcium: FoodAmount.milligrams(20),
                                .Potassium: FoodAmount.milligrams(15)
                            ]),
                        size: FoodSize(totalAmount: FoodAmount.grams(450), numServings: 5, servingSize: "1 unit"))
    context.insert(item)
    return item
}

@discardableResult
func createTestRecipeItem(_ context: ModelContext) -> Recipe {
    let recipe = Recipe(name: "Test Recipe",
                        metaData: RecipeMetaData(
                            details: "My fav waffles, some more text here just put them on the iron for a few minutes and eat",
                            prepTime: 8,
                            cookTime: 17,
                            otherTime: 0,
                            tags: ["Breakfast", "Bread"]),
                        instructions: [
                            RecipeSection(header: "Prep", details: "1. Put the mix with the water\n2. Mix until barely combined"),
                            RecipeSection(header: "Cook", details: "1. Put mix into the iron\n2. Wait until iron signals completion\n3. Remove and allow to cool")
                        ],
                        size: RecipeSize(
                            totalAmount: FoodAmount.grams(350),
                            cookedAmount: FoodAmount.grams(255),
                            numServings: 6,
                            servingSize: "1 waffle"),
                        nutrients: [
                            .Energy: FoodAmount.calories(200),
                            .TotalFat: FoodAmount.grams(4.1),
                            .SaturatedFat: FoodAmount.grams(2),
                            .TotalCarbs: FoodAmount.grams(20),
                            .DietaryFiber: FoodAmount.grams(1),
                            .TotalSugars: FoodAmount.grams(3),
                            .Protein: FoodAmount.grams(13.5)
                        ])
    context.insert(recipe)
    context.insert(RecipeIngredient(name: "Water", recipe: recipe, amount: FoodAmount(value: 1.2, unit: .Liter)))
    context.insert(RecipeIngredient(name: "Salt", recipe: recipe, amount: FoodAmount(value: 600, unit: .Milligram)))
    return recipe
}