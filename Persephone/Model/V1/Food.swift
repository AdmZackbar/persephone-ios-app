//
//  Food.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/17/25.
//

import Foundation
import SwiftData

typealias Food = SchemaV1.Food
typealias FoodSize = SchemaV1.FoodSize

extension SchemaV1 {
    @Model
    final class Food {
        var name: String = ""
        var metaData: MetaData = MetaData()
        var ingredients: FoodIngredients = FoodIngredients()
        var servingSize: FoodSize = FoodSize()
        var storeEntries: [StoreEntry] = []
        
        @Relationship(deleteRule: .cascade, inverse: \FoodInstance.food)
        var instances: [FoodInstance]! = []
        @Relationship(deleteRule: .cascade, inverse: \FoodLogEntry.food)
        var logEntries: [FoodLogEntry]! = []
        @Relationship(deleteRule: .cascade, inverse: \RecipeEntryIngredient.food)
        var recipeEntries: [RecipeEntryIngredient]! = []
        @Relationship(deleteRule: .cascade, inverse: \MealItem.food)
        var mealItems: [MealItem]! = []
        
        init(name: String = "",
             metaData: MetaData = .init(),
             ingredients: FoodIngredients = .init(),
             servingSize: FoodSize = .init(),
             storeEntries: [StoreEntry] = []) {
            self.name = name
            self.metaData = metaData
            self.ingredients = ingredients
            self.servingSize = servingSize
            self.storeEntries = storeEntries
        }
        
        struct MetaData: Codable {
            var timestamp: Date
            var barcode: String?
            var brand: String
            var category: String
            var notes: String
            var rating: Double?
            var retireDate: Date?
            
            init(timestamp: Date = .now,
                 barcode: String? = nil,
                 brand: String = "",
                 category: String = "",
                 notes: String = "",
                 rating: Double? = nil,
                 retireDate: Date? = nil) {
                self.timestamp = timestamp
                self.barcode = barcode
                self.brand = brand
                self.category = category
                self.notes = notes
                self.rating = rating
                self.retireDate = retireDate
            }
        }
        
        struct StoreEntry: Codable, Equatable, Hashable {
            var store: String = ""
            var cost: Currency = Currency.zero
            var amount: FoodSize = FoodSize()
            var isAvailable: Bool = true
            var isSale: Bool = false
            
            init(store: String = "",
                 cost: Currency = .zero,
                 amount: FoodSize = .init(),
                 isAvailable: Bool = true,
                 isSale: Bool = false) {
                self.store = store
                self.cost = cost
                self.amount = amount
                self.isAvailable = isAvailable
                self.isSale = isSale
            }
        }
    }
    
    struct FoodSize: Codable, Equatable, Hashable {
        var str: String
        var val: Double
        var isMass: Bool
        
        var amount: Amount {
            if let match = try? /^([\d\/.]+)?\s*(.+)$/.wholeMatch(in: str) {
                if let rawValue = match.1 {
                    if let value = Amount.Value.parse(String(rawValue)) {
                        .init(value: value, unitStr: String(match.2))
                    } else {
                        .init(value: .one)
                    }
                } else {
                    .init(value: .one, unitStr: String(match.2))
                }
            } else {
                .init(value: .one)
            }
        }
        var value: Amount {
            .init(value: .raw(val), unit: isMass ? .gram : .milliliter)
        }
        
        init(str: String = "",
             val: Double = 0,
             isMass: Bool = true) {
            self.str = str
            self.val = val
            self.isMass = isMass
        }
    }
}
