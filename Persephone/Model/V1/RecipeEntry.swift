//
//  RecipeEntry.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/20/25.
//

import Foundation
import SwiftData

typealias RecipeEntry = SchemaV1.RecipeEntry
typealias RecipeEntryIngredient = SchemaV1.RecipeEntryIngredient

extension SchemaV1 {
    @Model
    final class RecipeEntry {
        var date: Date = Date()
        var name: String = ""
        var notes: String? = nil
        var total: FoodSize = FoodSize()
        var retired: Bool = false
        
        @Relationship(deleteRule: .cascade, inverse: \RecipeEntryIngredient.recipe)
        var ingredients: [RecipeEntryIngredient]! = []
        @Relationship(deleteRule: .cascade, inverse: \RecipeLogEntry.recipe)
        var logEntries: [RecipeLogEntry]! = []
        
        init(date: Date = .now,
             name: String = "",
             notes: String? = nil,
             total: FoodSize = .init(),
             retired: Bool = false,
             ingredients: [RecipeEntryIngredient] = [],
             logEntries: [RecipeLogEntry] = []) {
            self.date = date
            self.name = name
            self.notes = notes
            self.total = total
            self.retired = retired
            self.ingredients = ingredients
            self.logEntries = logEntries
        }
    }
    
    @Model
    final class RecipeEntryIngredient {
        var recipe: RecipeEntry! = nil
        var food: Food! = nil
        var amount: Amount = Amount()
        var servingCost: Currency? = nil
        var notes: String? = nil
        
        init(recipe: RecipeEntry? = nil,
             food: Food? = nil,
             amount: Amount = .init(),
             servingCost: Currency? = nil,
             notes: String? = nil) {
            self.recipe = recipe
            self.food = food
            self.amount = amount
            self.servingCost = servingCost
            self.notes = notes
        }
    }
}
