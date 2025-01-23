//
//  LogEntry.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/22/25.
//

enum LogEntry: Hashable {
    case food(_ food: FoodLogEntry)
    case recipe(_ recipe: RecipeLogEntry)
    
    var meal: String {
        switch self {
        case .food(let food):
            food.meal
        case .recipe(let recipe):
            recipe.meal
        }
    }
    
    var nutrients: Nutrients {
        switch self {
        case .food(let food):
            food.nutrients
        case .recipe(let recipe):
            recipe.nutrients
        }
    }
    
    var cost: Currency? {
        switch self {
        case .food(let food):
            food.cost
        case .recipe(let recipe):
            recipe.cost
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
