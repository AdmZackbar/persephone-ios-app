//
//  FoodItem.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import Foundation
import SwiftData

typealias FoodItem = SchemaV1.FoodItem

extension SchemaV1 {
    @Model
    final class FoodItem {
        // The name of the item
        var name: String = ""
        // Any additional information about the item
        var details: String = ""
        // Metadata about the item
        var metaData: MetaData = MetaData()
        // Info about the ingredients and nutrition of the item
        var ingredients: FoodIngredients = FoodIngredients()
        // Info about the size of the item
        var size: Size = Size()
        // All store entries for the item
        var storeEntries: [StoreEntry] = []
        
        var bestStoreEntry: StoreEntry? {
            get {
                storeEntries.filter({ $0.available })
                    .min(by: { $0.costPerUnit(size: size) < $1.costPerUnit(size: size) })
            }
        }
        
        @Relationship(deleteRule: .cascade, inverse: \FoodInstance.foodItem)
        var instances: [FoodInstance]! = []
        @Relationship(deleteRule: .cascade, inverse: \LogFoodItemEntry.item)
        var logEntries: [LogFoodItemEntry]! = []
        @Relationship(deleteRule: .nullify, inverse: \RecipeIngredient.food)
        var recipeEntries: [RecipeIngredient]! = []
        
        init(name: String = "",
             details: String = "",
             metaData: MetaData = .init(),
             ingredients: FoodIngredients = .init(),
             size: Size = .init(),
             storeEntries: [StoreEntry] = []) {
            self.name = name
            self.details = details
            self.metaData = metaData
            self.ingredients = ingredients
            self.size = size
            self.storeEntries = storeEntries
        }
        
        struct MetaData: Codable {
            // When this item was recorded
            var timestamp: Date
            // The UPC barcode of the item
            var barcode: String?
            // The name of the brand that makes the item
            var brand: String?
            // The icon representing this item
            var icon: String?
            // Set of tags that describe this item
            var tags: [String]
            // Personal rating of the food [0,10] worst -> best
            var rating: Double?
            
            init(timestamp: Date = .now,
                 barcode: String? = nil,
                 brand: String? = nil,
                 icon: String? = nil,
                 tags: [String] = [],
                 rating: Double? = nil) {
                self.timestamp = timestamp
                self.barcode = barcode
                self.brand = brand
                self.icon = icon
                self.tags = tags
                self.rating = rating
            }
        }
        
        struct Size: Codable, Hashable, Equatable {
            // The empirical net weight/volume (e.g. net wt 10 lb)
            var totalAmount: Quantity
            // The total number of servings that the item contains
            var numServings: Double
            // The friendly serving size amount (e.g. 1 waffle, 2 portions, etc.)
            var servingSize: String
            // The empirical serving size (e.g. 54 g)
            var servingAmount: Quantity {
                get {
                    Quantity(value: totalAmount.value / numServings, unit: totalAmount.unit)
                }
                set(value) {
                    // Update number of servings instead of total amount
                    numServings = totalAmount.value.value / value.value.value
                }
            }
            var servingSizeAmount: Quantity {
                get {
                    if let match = try? /^([\d\/.]+)?\s*(.+)$/.wholeMatch(in: servingSize) {
                        if let rawValue = match.1 {
                            if let value = Quantity.Magnitude.parseString(String(rawValue)) {
                                Quantity(value: value, unit: .Custom(name: String(match.2)))
                            } else {
                                Quantity(value: .Raw(1), unit: .Serving)
                            }
                        } else {
                            Quantity(value: .Raw(1), unit: .Custom(name: String(match.2)))
                        }
                    } else {
                        Quantity(value: .Raw(1), unit: .Serving)
                    }
                }
            }
            
            init(totalAmount: Quantity = .grams(0),
                 numServings: Double = 1,
                 servingSize: String = "") {
                self.totalAmount = totalAmount
                self.numServings = numServings
                self.servingSize = servingSize
            }
        }
        
        struct StoreEntry: Codable, Equatable, Hashable {
            var storeName: String
            var costType: CostType
            var available: Bool = true
            var sale: Bool = false
            
            func costPerUnit(size: Size) -> Price {
                switch costType {
                case .Collection(let cost, let quantity):
                    cost / Double(quantity)
                case .PerAmount(let cost, let amount):
                    if amount.unit.isWeight && size.totalAmount.unit.isWeight {
                        try! cost * (size.totalAmount.convert(unit: .Gram).value.value / amount.convert(unit: .Gram).value.value)
                    } else if amount.unit.isVolume && size.totalAmount.unit.isVolume {
                        try! cost * (size.totalAmount.convert(unit: .Milliliter).value.value / amount.convert(unit: .Milliliter).value.value)
                    } else {
                        // TODO handle case
                        cost / amount.value.value
                    }
                }
            }
            
            func costPerServing(size: Size) -> Price {
                costPerUnit(size: size) / size.numServings
            }
            
            func costPerServingAmount(size: Size) -> Price {
                costPerServing(size: size) / size.servingSizeAmount.value.value
            }
            
            func costPerEnergy(foodItem: FoodItem) -> Price? {
                let caloriesPerServing = foodItem.ingredients.nutrients[.Energy]?.value.value ?? 0
                if caloriesPerServing <= 0 {
                    return nil
                }
                let totalCal = foodItem.size.numServings * caloriesPerServing
                return costPerUnit(size: foodItem.size) * (100 / totalCal)
            }
            
            func costPerWeight(size: Size) -> Price {
                try! costPerUnit(size: size) * (100 / size.totalAmount.convert(unit: .Gram).value.value)
            }
            
            func costPerVolume(size: Size) -> Price {
                try! costPerUnit(size: size) * (100 / size.totalAmount.convert(unit: .Milliliter).value.value)
            }
        }
        
        enum CostType: Codable, Equatable, Hashable {
            case Collection(cost: Price, quantity: Int)
            case PerAmount(cost: Price, amount: Quantity)
        }
    }
}
