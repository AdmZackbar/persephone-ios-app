//
//  FoodInstance.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/23/24.
//

import Foundation
import SwiftData

typealias FoodInstance = SchemaV1.FoodInstance

extension SchemaV1 {
    @Model
    final class FoodInstance {
        // The type of food
        var foodItem: FoodItem!
        // The cost of the food
        var price: Price
        // The amount of food that is left over
        var remaining: FoodAmount
        // The purchase date
        var buyDate: Date
        // The nominal expiration date
        var expDate: Date
        // The date this was frozen (if applicable)
        var freezeDate: Date?
        
        @Relationship(deleteRule: .cascade, inverse: \RecipeInstanceIngredient.food)
        var recipes: [RecipeInstanceIngredient] = []
        
        init(foodItem: FoodItem, price: Price, remaining: FoodAmount, buyDate: Date, expDate: Date, freezeDate: Date? = nil) {
            self.foodItem = foodItem
            self.price = price
            self.remaining = remaining
            self.buyDate = buyDate
            self.expDate = expDate
            self.freezeDate = freezeDate
        }
    }
}
