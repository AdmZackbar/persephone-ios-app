//
//  FoodInstance.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/23/24.
//

import Foundation
import SwiftData

typealias FoodInstance = SchemaV1.FoodInstance
typealias FoodInstanceDates = SchemaV1.FoodInstanceDates
typealias FoodInstanceAmount = SchemaV1.FoodInstanceAmount

extension SchemaV1 {
    @Model
    final class FoodInstance {
        // The type of food
        var foodItem: FoodItem!
        // The cost of the food
        var price: Price
        // The amount of food that is left over
        var amount: FoodInstanceAmount
        // Relevant dates pertaining to the food
        var dates: FoodInstanceDates
        
        @Relationship(deleteRule: .cascade, inverse: \RecipeInstanceIngredient.food)
        var recipes: [RecipeInstanceIngredient] = []
        
        init(foodItem: FoodItem, price: Price, amount: FoodInstanceAmount, dates: FoodInstanceDates) {
            self.foodItem = foodItem
            self.price = price
            self.amount = amount
            self.dates = dates
        }
    }
    
    struct FoodInstanceDates: Codable {
        // The purchase date
        var buyDate: Date
        // The nominal expiration date
        var expDate: Date
        // The date this was frozen (if applicable)
        var freezeDate: Date?
    }
    
    enum FoodInstanceAmount: Codable {
        // For items that you use a portion of at a time (typically)
        // e.g. carton of milk, 2 lbs of ground beef
        case Single(total: FoodAmount, remaining: FoodAmount)
        // For items that come in a package:
        // typically 1 item is used completely at a time
        // e.g. flat of coke cans, set of fairlife protein shakes
        case Collection(total: Int, remaining: Int)
    }
}
