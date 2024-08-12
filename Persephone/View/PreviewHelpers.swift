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
                        details: "Preparation: cook at 375 F for 12-14 minutes.",
                        metaData: FoodMetaData(barcode: "0123456789", brand: "Some Brand", tags: ["Bread"]),
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
                            ],
                            all: "Salt, Milk, Water, Pectin (for something or other).",
                            allergens: "Milk"
                        ),
                        size: FoodSize(totalAmount: FoodAmount.grams(450), numServings: 5, servingSize: "1 unit"))
    context.insert(item)
    let store = Store(name: "Costco")
    context.insert(store)
    item.storeItems.append(StoreItem(store: store, foodItem: item, quantity: 2, price: Price(cents: 699), available: true))
    let store2 = Store(name: "Publix")
    context.insert(store2)
    item.storeItems.append(StoreItem(store: store2, foodItem: item, quantity: 3, price: Price(cents: 1099), available: true))
    return item
}

@discardableResult
func createTestRecipeItem(_ context: ModelContext) -> Recipe {
    let recipe = Recipe(name: "Test Recipe",
                        metaData: Recipe.MetaData(
                            author: "Zach Wassynger",
                            details: "My fav waffles, some more text here just put them on the iron for a few minutes and eat",
                            prepTime: 8,
                            cookTime: 17,
                            otherTime: 0,
                            tags: ["Breakfast", "Bread"]),
                        instructions: [
                            Recipe.Section(header: "Prep", details: "1. Put the mix with the water\n2. Mix until barely combined"),
                            Recipe.Section(header: "Cook", details: "1. Put mix into the iron\n2. Wait until iron signals completion\n3. Remove and allow to cool")
                        ],
                        size: Recipe.Size(
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
    recipe.ingredients.append(contentsOf: [
        RecipeIngredient(name: "Water", recipe: recipe, amount: FoodAmount(value: 1.2, unit: .Liter), notes: "Tap water or else"),
        RecipeIngredient(name: "Salt", recipe: recipe, amount: FoodAmount(value: 600, unit: .Milligram))
    ])
    return recipe
}

@discardableResult
func createTestFoodInstance(_ context: ModelContext) -> FoodInstance {
    let item = FoodInstance(foodItem: createTestFoodItem(context), origin: .Store(store: "Costco", price: Price(cents: 530)), amount: .Single(total: FoodAmount(value: 530, unit: .Gram), remaining: FoodAmount(value: 420, unit: .Gram)), dates: FoodInstanceDates(acqDate: Date(), expDate: Date().addingTimeInterval(100000), freezeDate: Date().addingTimeInterval(3600)))
    context.insert(item)
    return item
}
