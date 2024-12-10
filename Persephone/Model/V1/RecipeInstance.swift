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
        var recipe: Recipe! = nil
        // The amount of food remaining from this batch
        var amount: FoodInstance.Amount = FoodInstance.Amount.Collection(total: 0, remaining: 0)
        // The relevant dates for this instance
        var dates: Dates = Dates(creationDate: Date(), expDate: Date())
        // Any notes on how it was made
        var prepNotes: String = ""
        // Any notes on its quality or anything after it was made
        var postNotes: String = ""
        
        @Relationship(deleteRule: .cascade, inverse: \RecipeInstanceIngredient.recipeInstance)
        var ingredients: [RecipeInstanceIngredient]! = []
        @Relationship(deleteRule: .cascade, inverse: \LogEntryRecipe.recipe)
        var logEntries: [LogEntryRecipe]! = []
        
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
        var name: String = ""
        // The recipe instance
        var recipeInstance: RecipeInstance! = nil
        // The food used in the creation of the recipe
        var food: FoodInstance? = nil
        // The amount of the food used
        var amount: Quantity = Quantity.grams(0)
        
        init(name: String, recipeInstance: RecipeInstance, food: FoodInstance? = nil, amount: Quantity) {
            self.name = name
            self.recipeInstance = recipeInstance
            self.food = food
            self.amount = amount
        }
    }
}
