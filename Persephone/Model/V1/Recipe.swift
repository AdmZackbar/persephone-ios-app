//
//  Recipe.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/16/24.
//

import Foundation
import SwiftData

typealias Recipe = SchemaV1.Recipe
typealias RecipeMetaData = SchemaV1.RecipeMetaData
typealias RecipeSection = SchemaV1.RecipeSection
typealias RecipeSize = SchemaV1.RecipeSize
typealias RecipeIngredient = SchemaV1.RecipeIngredient

extension SchemaV1 {
    @Model
    final class Recipe {
        // The name of the recipe
        var name: String
        // Metadata of the recipe
        var metaData: RecipeMetaData
        // Instructions (header -> details list)
        var instructions: [RecipeSection]
        // Size info of the recipe
        var size: RecipeSize
        // Nutrient information (nutrient -> amount per serving)
        var nutrients: [Nutrient : FoodAmount]
        
        @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
        var ingredients: [RecipeIngredient] = []
        @Relationship(deleteRule: .cascade, inverse: \RecipeInstance.recipe)
        var instances: [RecipeInstance] = []
        
        init(name: String, metaData: RecipeMetaData, instructions: [RecipeSection], size: RecipeSize, nutrients: [Nutrient : FoodAmount]) {
            self.name = name
            self.metaData = metaData
            self.instructions = instructions
            self.size = size
            self.nutrients = nutrients
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
        
        init(name: String, food: FoodItem? = nil, recipe: Recipe, amount: FoodAmount, notes: String? = nil) {
            self.name = name
            self.food = food
            self.recipe = recipe
            self.amount = amount
            self.notes = notes
        }
    }
    
    struct RecipeMetaData: Codable {
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
    }
    
    struct RecipeSection: Codable, Equatable, Hashable {
        // The header of the instruction section
        var header: String
        // The details of the instruction section
        var details: String
    }
    
    struct RecipeSize: Codable {
        // The empirical net weight/volume (e.g. net wt 10 lb)
        var totalAmount: FoodAmount
        // The total number of servings that the item contains
        var numServings: Double
        // The friendly serving size amount (e.g. 1 waffle, 2 portions, etc.)
        var servingSize: String
        // The empirical serving size (e.g. 54 g)
        var servingAmount: FoodAmount {
            get {
                FoodAmount(value: totalAmount.value / numServings, unit: totalAmount.unit)
            }
            set(value) {
                // Update number of servings instead of total amount
                numServings = totalAmount.value / value.value
            }
        }
    }
}
