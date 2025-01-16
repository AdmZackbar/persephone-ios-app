//
//  CookedFood.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/15/25.
//

import Foundation
import SwiftData

typealias CookedFood = SchemaV1.CookedFood
typealias CookedFoodIngredient = SchemaV1.CookedFoodIngredient

extension SchemaV1 {
    @Model
    final class CookedFood {
        var date: Date = Date()
        var name: String = ""
        var recipe: Recipe? = nil
        @Relationship(deleteRule: .cascade, inverse: \CookedFoodIngredient.cookedFood)
        var ingredients: [CookedFoodIngredient]! = []
        var notes: String = ""
        var total: Double = 0
        var remaining: Double = 0
        var adjustNutrition: NutritionDict = [:]
        var size: FoodItem.Size = FoodItem.Size.init()
        
        init(date: Date = Date(),
             name: String = "",
             recipe: Recipe? = nil,
             ingredients: [CookedFoodIngredient] = [],
             notes: String = "",
             total: Double = 0,
             remaining: Double = 0,
             adjustNutrition: NutritionDict = [:],
             size: FoodItem.Size = .init()) {
            self.name = name
            self.recipe = recipe
            self.ingredients = ingredients
            self.notes = notes
            self.total = total
            self.remaining = remaining
            self.adjustNutrition = adjustNutrition
            self.size = size
        }
    }
    
    @Model
    final class CookedFoodIngredient {
        var cookedFood: CookedFood! = nil
        var foodItem: FoodItem! = nil
        var amount: Quantity.Magnitude = Quantity.Magnitude.Raw(1)
        var amountUnit: Unit? = nil
        var unitPrice: Price? = nil
        var price: Price? {
            if let unitPrice {
                unitPrice * (amount.value / foodItem.size.numServings)
            } else {
                nil
            }
        }
        
        init(cookedFood: CookedFood? = nil,
             foodItem: FoodItem,
             amount: Quantity.Magnitude = .Raw(1),
             amountUnit: Unit? = nil,
             unitPrice: Price? = nil) {
            self.cookedFood = cookedFood
            self.foodItem = foodItem
            self.amount = amount
            self.amountUnit = amountUnit
            self.unitPrice = unitPrice
        }
    }
}
