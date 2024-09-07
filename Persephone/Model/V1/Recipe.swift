//
//  Recipe.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/16/24.
//

import Foundation
import SwiftData

typealias Recipe = SchemaV1.Recipe
typealias RecipeIngredient = SchemaV1.RecipeIngredient

extension SchemaV1 {
    @Model
    final class Recipe {
        // The name of the recipe
        var name: String
        // Metadata of the recipe
        var metaData: MetaData
        // Instructions (header -> details list)
        var instructions: [Section]
        // Size info of the recipe
        var size: Size
        var nutrients: [Nutrient : FoodAmount] {
            get {
                var nutrients: [Nutrient : FoodAmount] = [:]
                for ingredient in ingredients {
                    if let food = ingredient.food {
                        for nutrient in food.ingredients.nutrients.keys {
                            var scale: Double = 1
                            switch ingredient.amount.unit {
                            case .Custom(_):
                                // Assume serving
                                scale = ingredient.amount.value.toValue()
                            default:
                                if ingredient.amount.unit.isWeight() {
                                    try? scale = ingredient.amount.toGrams().value.toValue() / food.size.servingAmount.toGrams().value.toValue()
                                } else {
                                    try? scale = ingredient.amount.toMilliliters().value.toValue() / food.size.servingAmount.toMilliliters().value.toValue()
                                }
                            }
                            let foodNutrient = FoodAmount(value: food.ingredients.nutrients[nutrient]!.value * scale, unit: food.ingredients.nutrients[nutrient]!.unit)
                            if let n = nutrients[nutrient] {
                                nutrients[nutrient] = FoodAmount(value: n.value + foodNutrient.value, unit: n.unit)
                            } else {
                                nutrients[nutrient] = foodNutrient
                            }
                        }
                    }
                }
                return nutrients
            }
        }
        var estimatedCost: FoodItem.Cost {
            ingredients.reduce(FoodItem.Cost.Cents(0), { $0 + ($1.estimatedCost ?? FoodItem.Cost.Cents(0)) })
        }
        
        @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
        var ingredients: [RecipeIngredient] = []
        @Relationship(deleteRule: .cascade, inverse: \RecipeInstance.recipe)
        var instances: [RecipeInstance] = []
        
        init(name: String, metaData: MetaData, instructions: [Section], size: Size) {
            self.name = name
            self.metaData = metaData
            self.instructions = instructions
            self.size = size
        }
        
        struct MetaData: Codable {
            var author: String?
            // The description of the recipe
            var details: String
            // The amount of time to prep this recipe (min)
            var prepTime: Double
            // The amount of time to cook this recipe (min)
            var cookTime: Double
            // Any additional time used in this recipe (min)
            var otherTime: Double
            // The total time used for this entire recipe (min)
            var totalTime: Double {
                get {
                    prepTime + cookTime + otherTime
                }
                set(value) {
                    otherTime = value - prepTime - cookTime
                }
            }
            // Any tags used to describe this recipe
            var tags: [String]
            // Personal rating of the recipe [0,10] worst -> best
            var rating: Double?
            // Personal rating of the recipe (after being frozen or eaten later)
            var ratingLeftover: Double?
            // Estimated difficulty to make the recipe [0,10] easiest -> hardest
            var difficulty: Double?
        }
        
        struct Section: Codable, Equatable, Hashable {
            // The header of the instruction section
            var header: String
            // The details of the instruction section
            var details: String
        }
        
        struct Size: Codable {
            // The total number of servings that the item contains
            var numServings: Double
            // The friendly serving size amount (e.g. 1 waffle, 2 portions, etc.)
            var servingSize: String
        }
        
        enum DifficultyLevel: String, CaseIterable, Codable, Identifiable {
            var id: String {
                get {
                    rawValue
                }
            }
            
            case Trivial, Easy, Medium, Hard, Insane
            
            func getValue() -> Double {
                switch self {
                case .Trivial:
                    1
                case .Easy:
                    3
                case .Medium:
                    5
                case .Hard:
                    7
                case .Insane:
                    9
                }
            }
            
            static func fromValue(value: Double?) -> DifficultyLevel? {
                if value == nil {
                    return nil
                }
                let value = value!
                if value > 8 {
                    return .Insane
                }
                if value > 6 {
                    return .Hard
                }
                if value > 4 {
                    return .Medium
                }
                if value > 2 {
                    return .Easy
                }
                return .Trivial
            }
        }
    }
    
    @Model
    final class RecipeIngredient {
        // The name of the food ingredient
        var name: String
        // Optional link to the food item itself
        var food: FoodItem?
        // The recipe of this ingredient
        var recipe: Recipe!
        // The amount used
        var amount: FoodAmount
        // Optional notes on this ingredient
        var notes: String?
        var estimatedCost: FoodItem.Cost? {
            if let food {
                if let storeEntry = food.storeEntries
                    .sorted(by: { $0.costPerUnit(size: food.size) < $1.costPerUnit(size: food.size) })
                    .first {
                    let costPerServing = storeEntry.costPerServing(size: food.size)
                    return costPerServing * computeNumServings(food: food) * 100
                }
            }
            return nil
        }
        
        init(name: String, food: FoodItem? = nil, recipe: Recipe, amount: FoodAmount, notes: String? = nil) {
            self.name = name
            self.food = food
            self.recipe = recipe
            self.amount = amount
            self.notes = notes
        }
        
        func amountToString() -> String {
            if let food {
                switch amount.unit {
                case .Custom(_):
                    // Assume 'serving'
                    let servingValue = (amount.value * food.size.servingSizeAmount.value.toValue()).toString()
                    let servingUnit = food.size.servingSizeAmount.unit.getAbbreviation().lowercased()
                    let totalAmountValue = (food.size.servingAmount.value * amount.value.toValue()).toString()
                    let totalAmountUnit = food.size.servingAmount.unit.getAbbreviation()
                    return "\(servingValue) \(servingUnit) (\(totalAmountValue) \(totalAmountUnit))"
                default:
                    break
                }
            }
            return "\(amount.value.toString()) \(amount.unit.getAbbreviation())"
        }
        
        func computeNumServings(food: FoodItem) -> Double {
            if amount.unit.isWeight() {
                return try! amount.toGrams().value.toValue() / food.size.servingAmount.toGrams().value.toValue()
            } else if amount.unit.isVolume() {
                return try! amount.toMilliliters().value.toValue() / food.size.servingAmount.toMilliliters().value.toValue()
            }
            // Assume servings
            return amount.value.toValue()
        }
    }
}
