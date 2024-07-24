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
        var remaining: FoodAmount
        // The date it was created
        var creationDate: Date
        // The nominal expiration date
        var expDate: Date
        // The date this was frozen (if applicable)
        var freezeDate: Date?
        // Any notes on how it was made
        var prepNotes: String
        // Any notes on its quality or anything after it was made
        var postNotes: String
        
        @Relationship(deleteRule: .cascade, inverse: \RecipeInstanceIngredient.recipeInstance)
        var ingredients: [RecipeInstanceIngredient] = []
        
        init(recipe: Recipe!, remaining: FoodAmount, creationDate: Date, expDate: Date, freezeDate: Date? = nil, prepNotes: String, postNotes: String) {
            self.recipe = recipe
            self.remaining = remaining
            self.creationDate = creationDate
            self.expDate = expDate
            self.freezeDate = freezeDate
            self.prepNotes = prepNotes
            self.postNotes = postNotes
        }
    }
    
    @Model
    final class RecipeInstanceIngredient {
        // The recipe instance
        var recipeInstance: RecipeInstance!
        // The food used in the creation of the recipe
        var food: FoodInstance!
        // The amount of the food used
        var amount: FoodAmount
        
        init(recipeInstance: RecipeInstance!, food: FoodInstance!, amount: FoodAmount) {
            self.recipeInstance = recipeInstance
            self.food = food
            self.amount = amount
        }
    }
}
