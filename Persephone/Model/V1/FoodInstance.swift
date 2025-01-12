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
        var foodItem: FoodItem! = nil
        // The origin of the food (store bought, gifted, grown)
        var origin: Origin? = nil
        // The amount of food that is left over
        var amount: Amount = Amount.Single(total: .grams(0), remaining: .grams(0))
        // Relevant dates pertaining to the food
        var dates: Dates = Dates(acqDate: .now)
        
        @Relationship(deleteRule: .cascade, inverse: \RecipeInstanceIngredient.food)
        var recipes: [RecipeInstanceIngredient]! = []
        
        init(foodItem: FoodItem,
             origin: Origin? = nil,
             amount: Amount = .Collection(total: 1, remaining: 1),
             dates: Dates = .init()) {
            self.foodItem = foodItem
            self.origin = origin
            self.amount = amount
            self.dates = dates
        }
        
        enum Origin: Codable {
            // Store-bought
            case Store(store: String, price: Price)
            // Obtained for free from someone/somewhere
            case Gift(from: String)
            // Grown and obtained in some organic manner
            case Grown(location: String)
        }
        
        struct Dates: Codable {
            // The acquisition date
            var acqDate: Date
            // The nominal expiration date
            var expDate: Date?
            // The date this was frozen (if applicable)
            var freezeDate: Date?
            
            init(acqDate: Date = Date(),
                 expDate: Date? = nil,
                 freezeDate: Date? = nil) {
                self.acqDate = acqDate
                self.expDate = expDate
                self.freezeDate = freezeDate
            }
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
