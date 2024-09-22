//
//  LogbookItem.swift
//  Persephone
//
//  Created by Zach Wassynger on 9/15/24.
//

import Foundation
import SwiftData

typealias LogbookItem = SchemaV1.LogbookItem
typealias LogbookFoodItemEntry = SchemaV1.LogbookFoodItemEntry

extension SchemaV1 {
    @Model
    final class LogbookItem {
        @Attribute(.unique) var date: Date
        var targetNutrients: NutritionDict
        
        // Computes the aggregate of all nutrients
        var nutrients: NutritionDict {
            get {
                var nutrients: NutritionDict = [:]
                for entry in foodEntries {
                    if let food = entry.foodItem {
                        for nutrient in food.ingredients.nutrients.keys {
                            var scale: Double = 1
                            switch entry.amount.unit {
                            case .Serving, .Custom(_):
                                // Assume serving
                                scale = entry.amount.value.value
                            default:
                                if entry.amount.unit.isWeight {
                                    try? scale = entry.amount.toGrams().value.value / food.size.servingAmount.toGrams().value.value
                                } else {
                                    try? scale = entry.amount.toMilliliters().value.value / food.size.servingAmount.toMilliliters().value.value
                                }
                            }
                            let foodNutrient = Quantity(value: food.ingredients.nutrients[nutrient]!.value * scale, unit: food.ingredients.nutrients[nutrient]!.unit)
                            if let n = nutrients[nutrient] {
                                nutrients[nutrient] = Quantity(value: n.value + foodNutrient.value, unit: n.unit)
                            } else {
                                nutrients[nutrient] = foodNutrient
                            }
                        }
                    }
                }
                return nutrients
            }
        }
        
        @Relationship(deleteRule: .cascade, inverse: \LogbookFoodItemEntry.logItem)
        var foodEntries: [LogbookFoodItemEntry] = []
        
        init(date: Date, targetNutrients: NutritionDict = [:]) {
            // Enforce that all dates are agnostic of time
            self.date = Calendar.current.startOfDay(for: date)
            self.targetNutrients = targetNutrients
        }
        
        enum MealType: String, Codable {
            case Breakfast
            case Lunch
            case Dinner
            case Snacks
            case Dessert
        }
        
        func computeNutrients(mealType: MealType) -> NutritionDict {
            var nutrients: NutritionDict = [:]
            for entry in foodEntries.filter({ $0.mealType == mealType }) {
                if let food = entry.foodItem {
                    for nutrient in food.ingredients.nutrients.keys {
                        var scale: Double = 1
                        switch entry.amount.unit {
                        case .Serving, .Custom(_):
                            // Assume serving
                            scale = entry.amount.value.value
                        default:
                            if entry.amount.unit.isWeight {
                                try? scale = entry.amount.toGrams().value.value / food.size.servingAmount.toGrams().value.value
                            } else {
                                try? scale = entry.amount.toMilliliters().value.value / food.size.servingAmount.toMilliliters().value.value
                            }
                        }
                        let foodNutrient = Quantity(value: food.ingredients.nutrients[nutrient]!.value * scale, unit: food.ingredients.nutrients[nutrient]!.unit)
                        if let n = nutrients[nutrient] {
                            nutrients[nutrient] = Quantity(value: n.value + foodNutrient.value, unit: n.unit)
                        } else {
                            nutrients[nutrient] = foodNutrient
                        }
                    }
                }
            }
            return nutrients
        }
    }
    
    @Model
    final class LogbookFoodItemEntry {
        var logItem: LogbookItem!
        var foodItem: FoodItem!
        var amount: Quantity
        var mealType: LogbookItem.MealType
        
        init(logItem: LogbookItem, foodItem: FoodItem, amount: Quantity, mealType: LogbookItem.MealType) {
            self.logItem = logItem
            self.foodItem = foodItem
            self.amount = amount
            self.mealType = mealType
        }
    }
}
