//
//  LogEntryItem.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/22/25.
//

import Foundation
import SwiftData

struct LogEntryItem {
    private var entry: LogEntry?
    var isEdit: Bool {
        entry != nil
    }
    
    var isInvalid: Bool {
        switch type {
        case .food:
            food == nil ||
            amount.value.raw <= 0 ||
            meal == ""
        case .recipe:
            recipe == nil ||
            amount.value.raw <= 0 ||
            meal == ""
        }
    }
    
    // General
    var type: LogEntryType
    var date: Date
    var meal: String
    var amount: Amount
    // Food
    var food: Food?
    var servingCost: Currency?
    // Recipe
    var recipe: RecipeEntry?
    
    var numServings: Double {
        switch type {
        case .food:
            // Amount / Serving Amount
            if let food {
                if let modifier = amount.unit?.modifier {
                    return (amount.value.raw * modifier) / food.servingSize.val
                }
                return amount.value.raw / food.servingSize.amount.value.raw
            }
        case .recipe:
            if let recipe {
                if let modifier = amount.unit?.modifier {
                    return (amount.value.raw * modifier) / recipe.total.val
                }
                return amount.value.raw
            }
        }
        return amount.value.raw
    }
    var size: FoodSize? {
        switch type {
        case .food:
            if let food {
                return food.servingSize * numServings
            }
        case .recipe:
            if let recipe {
                return recipe.total * (numServings / recipe.totalNumServings)
            }
        }
        return nil
    }
    var remainingScale: Double? {
        if let recipe {
            switch entry {
            case .recipe(let r):
                min(1, max(0, 1 - (recipe.logEntries ?? []).filter({ $0 != r }).map({ $0.amount.value.raw }).reduce(0, +)))
            default:
                min(1, max(0, 1 - recipe.usedScale))
            }
        } else {
            nil
        }
    }
    
    init(entry: LogEntry) {
        self.entry = entry
        switch entry {
        case .food(let food):
            self.type = .food
            self.date = food.date
            self.food = food.food
            self.amount = food.amount
            self.meal = food.meal
            self.servingCost = food.servingCost
            self.recipe = nil
        case .recipe(let recipe):
            self.type = .recipe
            self.date = recipe.date
            self.recipe = recipe.recipe
            self.amount = recipe.amount
            self.meal = recipe.meal
            self.food = nil
            self.servingCost = nil
        }
    }
    
    init(date: Date = .now,
         meal: String = "") {
        self.entry = nil
        self.type = .food
        self.date = date
        self.food = nil
        self.recipe = nil
        self.meal = meal
        self.servingCost = nil
        self.amount = .init(value: .zero)
    }
    
    func save(_ modelContext: ModelContext) {
        switch entry {
        case .food(let foodEntry):
            switch type {
            case .food:
                editFood(foodEntry)
            case .recipe:
                modelContext.delete(foodEntry)
                createRecipe(modelContext)
            }
        case .recipe(let recipeEntry):
            switch type {
            case .recipe:
                editRecipe(recipeEntry)
            case .food:
                modelContext.delete(recipeEntry)
                createFood(modelContext)
            }
        case nil:
            switch type {
            case .food:
                createFood(modelContext)
            case .recipe:
                createRecipe(modelContext)
            }
        }
    }
    
    func createFood(_ modelContext: ModelContext) {
        let foodEntry = FoodLogEntry(date: date, food: food, amount: amount, meal: meal, servingCost: servingCost)
        modelContext.insert(foodEntry)
    }
    
    func editFood(_ foodEntry: FoodLogEntry) {
        foodEntry.date = date
        foodEntry.food = food
        foodEntry.amount = amount
        foodEntry.meal = meal
        foodEntry.servingCost = servingCost
    }
    
    func createRecipe(_ modelContext: ModelContext) {
        let recipeEntry = RecipeLogEntry(date: date, recipe: recipe, amount: amount, meal: meal)
        modelContext.insert(recipeEntry)
    }
    
    func editRecipe(_ recipeEntry: RecipeLogEntry) {
        recipeEntry.date = date
        recipeEntry.recipe = recipe
        recipeEntry.amount = amount
        recipeEntry.meal = meal
    }
    
    enum LogEntryType: String, CaseIterable {
        case food
        case recipe
    }
}
