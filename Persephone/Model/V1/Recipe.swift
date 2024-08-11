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
        // Nutrient information (nutrient -> amount per serving)
        var nutrients: [Nutrient : FoodAmount]
        
        @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
        var ingredients: [RecipeIngredient] = []
        @Relationship(deleteRule: .cascade, inverse: \RecipeInstance.recipe)
        var instances: [RecipeInstance] = []
        
        init(name: String, metaData: MetaData, instructions: [Section], size: Size, nutrients: [Nutrient : FoodAmount]) {
            self.name = name
            self.metaData = metaData
            self.instructions = instructions
            self.size = size
            self.nutrients = nutrients
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
}
