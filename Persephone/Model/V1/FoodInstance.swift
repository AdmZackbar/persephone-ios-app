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
        // The origin of the food (store bought, gifted, grown)
        var origin: Origin
        // The amount of food that is left over
        var amount: Amount
        // Relevant dates pertaining to the food
        var dates: Dates
        
        @Relationship(deleteRule: .cascade, inverse: \RecipeInstanceIngredient.food)
        var recipes: [RecipeInstanceIngredient] = []
        
        init(foodItem: FoodItem, origin: Origin, amount: Amount, dates: Dates) {
            self.foodItem = foodItem
            self.origin = origin
            self.amount = amount
            self.dates = dates
        }
        
        enum Origin: Codable {
            // Store-bought
            case Store(store: String, cost: FoodItem.Cost)
            // Obtained for free from someone/somewhere
            case Gift(from: String)
            // Grown and obtained in some organic manner
            case Grown(location: String)
        }
        
        struct Dates: Codable {
            // The acquisition date
            var acqDate: Date
            // The nominal expiration date
            var expDate: Date
            // The date this was frozen (if applicable)
            var freezeDate: Date?
        }
        
        enum Amount: Codable {
            // For items that you use a portion of at a time (typically)
            // e.g. carton of milk, 2 lbs of ground beef
            case Single(total: Quantity, remaining: Quantity)
            // For items that come in a package:
            // typically 1 item is used completely at a time
            // e.g. flat of coke cans, set of fairlife protein shakes
            case Collection(total: Int, remaining: Int)
        }
    }
}
