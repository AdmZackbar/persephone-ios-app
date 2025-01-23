//
//  RecipeEntryItem.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/20/25.
//

import Foundation

struct RecipeEntryItem {
    private var entry: RecipeEntry?
    var isEdit: Bool {
        entry != nil
    }
    
    var date: Date
    var name: String
    var notes: String
    var total: FoodSize
    var removedScale: Double
    var ingredients: [RecipeEntryIngredient]
    
    var isInvalid: Bool {
        name.isEmpty || total.str.isEmpty || total.amount.value.raw <= 0 || removedScale < 0 || removedScale > 1
    }
    
    init(entry: RecipeEntry? = nil) {
        self.entry = entry
        self.date = entry?.date ?? .now
        self.name = entry?.name ?? ""
        self.notes = entry?.notes ?? ""
        self.total = entry?.total ?? .init()
        self.removedScale = entry?.removedScale ?? 1
        self.ingredients = entry?.ingredients ?? []
    }
    
    mutating func save() -> RecipeEntry? {
        if let entry {
            entry.date = date
            entry.name = name
            entry.notes = notes.isEmpty ? nil : notes
            entry.total = total
            entry.removedScale = removedScale
            entry.ingredients = ingredients
            return nil
        }
        entry = .init(date: date, name: name, notes: notes.isEmpty ? nil : notes, total: total, removedScale: removedScale, ingredients: ingredients)
        return entry
    }
}

struct RecipeEntryIngredientItem {
    private var ingredient: RecipeEntryIngredient?
    var isEdit: Bool {
        ingredient != nil
    }
    
    var food: Food?
    var amount: Amount
    var servingCost: Currency?
    var notes: String
    
    var isInvalid: Bool {
        food == nil || amount.value.raw <= 0
    }
    
    init(ingredient: RecipeEntryIngredient? = nil) {
        self.ingredient = ingredient
        self.food = ingredient?.food
        self.amount = ingredient?.amount ?? .init()
        self.servingCost = ingredient?.servingCost
        self.notes = ingredient?.notes ?? ""
    }
    
    mutating func save() -> RecipeEntryIngredient? {
        if let ingredient {
            ingredient.food = food
            ingredient.amount = amount
            ingredient.servingCost = servingCost
            ingredient.notes = notes.isEmpty ? nil : notes
            return nil
        }
        ingredient = .init(food: food, amount: amount, servingCost: servingCost, notes: notes.isEmpty ? nil : notes)
        return ingredient
    }
}
