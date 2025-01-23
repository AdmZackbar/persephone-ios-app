//
//  LogEntry.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/22/25.
//

import Foundation

enum LogEntry: Hashable {
    case food(_ foodEntry: FoodLogEntry)
    case recipe(_ recipeEntry: RecipeLogEntry)
    
    var date: Date {
        switch self {
        case .food(let entry):
            entry.date
        case .recipe(let entry):
            entry.date
        }
    }
    var name: String {
        switch self {
        case .food(let entry):
            entry.food.name
        case .recipe(let entry):
            entry.recipe.name
        }
    }
    var meal: String {
        switch self {
        case .food(let entry):
            entry.meal
        case .recipe(let entry):
            entry.meal
        }
    }
    var amount: Amount {
        switch self {
        case .food(let entry):
            entry.amount
        case .recipe(let entry):
            entry.amount
        }
    }
    var nutrients: Nutrients {
        switch self {
        case .food(let entry):
            entry.nutrients
        case .recipe(let entry):
            entry.nutrients
        }
    }
    var cost: Currency? {
        switch self {
        case .food(let entry):
            entry.cost
        case .recipe(let entry):
            entry.cost
        }
    }
    var brand: String? {
        switch self {
        case .food(let entry):
            entry.food.brand
        default:
            nil
        }
    }
}

extension [LogEntry] {
    var nutrients: Nutrients {
        self.map({ $0.nutrients }).reduce([:], +)
    }
    
    var cost: Currency? {
        let filtered = self.filter({ $0.cost != nil })
        if filtered.isEmpty {
            return nil
        }
        return filtered.map({ $0.cost! }).reduce(.zero, +)
    }
}
