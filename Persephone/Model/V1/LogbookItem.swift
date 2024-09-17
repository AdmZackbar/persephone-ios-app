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
        var targetNutrients: [Nutrient : FoodAmount]
        
        // Computes the aggregate of all nutrients
        var nutrients: [Nutrient : FoodAmount] {
            get {
                var nutrients: [Nutrient : FoodAmount] = [:]
                for entry in foodEntries {
                    if let food = entry.foodItem {
                        for nutrient in food.ingredients.nutrients.keys {
                            var scale: Double = 1
                            switch entry.amount.unit {
                            case .Custom(_):
                                // Assume serving
                                scale = entry.amount.value.toValue()
                            default:
                                if entry.amount.unit.isWeight() {
                                    try? scale = entry.amount.toGrams().value.toValue() / food.size.servingAmount.toGrams().value.toValue()
                                } else {
                                    try? scale = entry.amount.toMilliliters().value.toValue() / food.size.servingAmount.toMilliliters().value.toValue()
                                }
                            }
                            let foodNutrient = FoodAmount(value: food.ingredients.nutrients[nutrient]!.value * scale, unit: food.ingredients.nutrients[nutrient]!.unit)
                            if let n = nutrients[nutrient] {
                                nutrients[nutrient] = FoodAmount(value: n.value + foodNutrient.value, unit: n.unit)
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
        
        init(date: Date, targetNutrients: [Nutrient : FoodAmount] = [:]) {
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
        
        func computeNutrients(mealType: MealType) -> [Nutrient : FoodAmount] {
            var nutrients: [Nutrient : FoodAmount] = [:]
            for entry in foodEntries.filter({ $0.mealType == mealType }) {
                if let food = entry.foodItem {
                    for nutrient in food.ingredients.nutrients.keys {
                        var scale: Double = 1
                        switch entry.amount.unit {
                        case .Custom(_):
                            // Assume serving
                            scale = entry.amount.value.toValue()
                        default:
                            if entry.amount.unit.isWeight() {
                                try? scale = entry.amount.toGrams().value.toValue() / food.size.servingAmount.toGrams().value.toValue()
                            } else {
                                try? scale = entry.amount.toMilliliters().value.toValue() / food.size.servingAmount.toMilliliters().value.toValue()
                            }
                        }
                        let foodNutrient = FoodAmount(value: food.ingredients.nutrients[nutrient]!.value * scale, unit: food.ingredients.nutrients[nutrient]!.unit)
                        if let n = nutrients[nutrient] {
                            nutrients[nutrient] = FoodAmount(value: n.value + foodNutrient.value, unit: n.unit)
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
        var amount: FoodAmount
        var mealType: LogbookItem.MealType
        
        init(logItem: LogbookItem, foodItem: FoodItem, amount: FoodAmount, mealType: LogbookItem.MealType) {
            self.logItem = logItem
            self.foodItem = foodItem
            self.amount = amount
            self.mealType = mealType
        }
    }
}
