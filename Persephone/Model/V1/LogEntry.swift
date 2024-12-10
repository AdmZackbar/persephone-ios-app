//
//  LogEntry.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/23/24.
//

import Foundation
import SwiftData

extension SchemaV1 {
    @Model
    final class LogEntry {
        // The date of this log entry
        var date: Date = Date()
        
        @Relationship(deleteRule: .cascade, inverse: \LogEntryFoodInstance.logEntry)
        var foodInstances: [LogEntryFoodInstance]! = []
        @Relationship(deleteRule: .cascade, inverse: \LogEntryFood.logEntry)
        var foods: [LogEntryFood]! = []
        @Relationship(deleteRule: .cascade, inverse: \LogEntryRecipe.logEntry)
        var recipes: [LogEntryRecipe]! = []
        
        init(date: Date) {
            self.date = date
        }
    }
    
    @Model
    final class LogEntryFoodInstance {
        // The log entry
        var logEntry: LogEntry! = nil
        // The logged food instance
        var food: FoodInstance! = nil
        // If false, this is just a planned entry
        var confirmed: Bool = false
        
        init(logEntry: LogEntry, food: FoodInstance, confirmed: Bool) {
            self.logEntry = logEntry
            self.food = food
            self.confirmed = confirmed
        }
    }
    
    @Model
    final class LogEntryFood {
        var logEntry: LogEntry! = nil
        var food: FoodItem! = nil
        var confirmed: Bool = false
        
        init(logEntry: LogEntry, food: FoodItem, confirmed: Bool) {
            self.logEntry = logEntry
            self.food = food
            self.confirmed = confirmed
        }
    }
    
    @Model
    final class LogEntryRecipe {
        var logEntry: LogEntry! = nil
        var recipe: RecipeInstance! = nil
        var confirmed: Bool = false
        
        init(logEntry: LogEntry, recipe: RecipeInstance, confirmed: Bool) {
            self.logEntry = logEntry
            self.recipe = recipe
            self.confirmed = confirmed
        }
    }
}
