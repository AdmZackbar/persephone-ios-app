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
        var date: Date = Date()
        var targetNutrients: NutritionDict = [:]
        
        // Computes the aggregate of all nutrients
        var nutrients: NutritionDict {
            get {
                var nutrients: NutritionDict = [:]
                for entry in foodEntries {
                    if let food = entry.foodItem {
                        for nutrient in food.ingredients.nutrients.keys {
                            var scale: Double = 1
                            if entry.amount.unit.isWeight {
                                try? scale = entry.amount.convert(unit: .Gram).value.value / food.size.servingAmount.convert(unit: .Gram).value.value
                            } else if entry.amount.unit.isVolume {
                                try? scale = entry.amount.convert(unit: .Milliliter).value.value / food.size.servingAmount.convert(unit: .Milliliter).value.value
                            } else {
                                // Assume serving
                                scale = entry.amount.value.value
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
        var foodEntries: [LogbookFoodItemEntry]! = []
        
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
                        if entry.amount.unit.isWeight {
                            try? scale = entry.amount.convert(unit: .Gram).value.value / food.size.servingAmount.convert(unit: .Gram).value.value
                        } else if entry.amount.unit.isVolume {
                            try? scale = entry.amount.convert(unit: .Milliliter).value.value / food.size.servingAmount.convert(unit: .Milliliter).value.value
                        } else {
                            // Assume serving
                            scale = entry.amount.value.value
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
        var logItem: LogbookItem! = nil
        var foodItem: FoodItem! = nil
        var amount: Quantity = Quantity.grams(0)
        var mealType: LogbookItem.MealType = LogbookItem.MealType.Breakfast
        
        init(logItem: LogbookItem, foodItem: FoodItem, amount: Quantity, mealType: LogbookItem.MealType) {
            self.logItem = logItem
            self.foodItem = foodItem
            self.amount = amount
            self.mealType = mealType
        }
    }
}
