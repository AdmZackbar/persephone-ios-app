//
//  RecipeInstance.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/23/24.
//

import Foundation
import SwiftData

typealias RecipeInstance = SchemaV1.RecipeInstance
typealias RecipeInstanceIngredient = SchemaV1.RecipeInstanceIngredient

extension SchemaV1 {
    @Model
    final class RecipeInstance {
        // The recipe this is based on
        var recipe: Recipe!
        // The amount of food remaining from this batch
        var amount: FoodInstance.Amount
        // The relevant dates for this instance
        var dates: Dates
        // Any notes on how it was made
        var prepNotes: String
        // Any notes on its quality or anything after it was made
        var postNotes: String
        
        @Relationship(deleteRule: .cascade, inverse: \RecipeInstanceIngredient.recipeInstance)
        var ingredients: [RecipeInstanceIngredient] = []
        
        init(recipe: Recipe, amount: FoodInstance.Amount, dates: Dates, prepNotes: String, postNotes: String) {
            self.recipe = recipe
            self.amount = amount
            self.dates = dates
            self.prepNotes = prepNotes
            self.postNotes = postNotes
        }
        
        struct Dates: Codable {
            // The date it was created
            var creationDate: Date
            // The nominal expiration date
            var expDate: Date
            // The date this was frozen (if applicable)
            var freezeDate: Date?
        }
    }
    
    @Model
    final class RecipeInstanceIngredient {
        // The name of the ingredient/food
        var name: String
        // The recipe instance
        var recipeInstance: RecipeInstance!
        // The food used in the creation of the recipe
        var food: FoodInstance?
        // The amount of the food used
        var amount: FoodAmount
        
        init(name: String, recipeInstance: RecipeInstance, food: FoodInstance? = nil, amount: FoodAmount) {
            self.name = name
            self.recipeInstance = recipeInstance
            self.food = food
            self.amount = amount
        }
    }
}
