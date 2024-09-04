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
        var name: String
        // Any additional information about the item
        var details: String
        // Metadata about the item
        var metaData: MetaData
        // Info about the ingredients and nutrition of the item
        var ingredients: FoodIngredients
        // Info about the size of the item
        var size: Size
        // All store entries for the item
        var storeEntries: [StoreEntry]
        
        @Relationship(deleteRule: .nullify, inverse: \RecipeIngredient.food)
        var recipeEntries: [RecipeIngredient] = []
        
        init(name: String, details: String, metaData: MetaData, ingredients: FoodIngredients, size: Size, storeEntries: [StoreEntry]) {
            self.name = name
            self.details = details
            self.metaData = metaData
            self.ingredients = ingredients
            self.size = size
            self.storeEntries = storeEntries
        }
        
        func getNutrient(_ nutrient: Nutrient, numServings: Double = 1.0) -> FoodAmount? {
            if let value = ingredients.nutrients[nutrient] {
                return FoodAmount(value: value.value * numServings, unit: value.unit)
            }
            return nil
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
            // An image of the item
            @Attribute(.externalStorage) var imageData: Data?
            // Set of tags that describe this item
            var tags: [String]
            // Personal rating of the food [0,10] worst -> best
            var rating: Double?
            
            init(timestamp: Date = .now, barcode: String? = nil, brand: String? = nil, icon: String? = nil, imageData: Data? = nil, tags: [String] = [], rating: Double? = nil) {
                self.timestamp = timestamp
                self.barcode = barcode
                self.brand = brand
                self.icon = icon
                self.imageData = imageData
                self.tags = tags
                self.rating = rating
            }
        }
        
        struct Size: Codable {
            // The empirical net weight/volume (e.g. net wt 10 lb)
            var totalAmount: FoodAmount
            // The total number of servings that the item contains
            var numServings: Double
            // The friendly serving size amount (e.g. 1 waffle, 2 portions, etc.)
            var servingSize: String
            // The empirical serving size (e.g. 54 g)
            var servingAmount: FoodAmount {
                get {
                    FoodAmount(value: totalAmount.value / numServings, unit: totalAmount.unit)
                }
                set(value) {
                    // Update number of servings instead of total amount
                    numServings = totalAmount.value.toValue() / value.value.toValue()
                }
            }
            var servingSizeAmount: FoodAmount {
                get {
                    if let match = try? /^([\d\/.]+)?\s*(.+)$/.wholeMatch(in: servingSize) {
                        if let rawValue = match.1?.string {
                            if let value = FoodAmount.Value.parseString(rawValue) {
                                FoodAmount(value: value, unit: .Custom(name: match.2.string))
                            } else {
                                FoodAmount(value: .Raw(1), unit: .Custom(name: "serving"))
                            }
                        } else {
                            FoodAmount(value: .Raw(1), unit: .Custom(name: match.2.string))
                        }
                    } else {
                        FoodAmount(value: .Raw(1), unit: .Custom(name: "serving"))
                    }
                }
            }
        }
        
        struct StoreEntry: Codable, Equatable, Hashable {
            var storeName: String
            var costType: CostType
            var available: Bool
            
            func costPerUnit(size: Size) -> Double {
                switch costType {
                case .Collection(let cost, let quantity):
                    cost.toUsd() / Double(quantity)
                case .PerAmount(let cost, let amount):
                    if amount.unit.isWeight() && size.totalAmount.unit.isWeight() {
                        cost.toUsd() / Double(amount.value.toValue()) * (try! size.totalAmount.toGrams().value.toValue() / amount.toGrams().value.toValue())
                    } else if amount.unit.isVolume() && size.totalAmount.unit.isVolume() {
                        cost.toUsd() / Double(amount.value.toValue()) * (try! size.totalAmount.toMilliliters().value.toValue() / amount.toMilliliters().value.toValue())
                    } else {
                        // TODO handle case
                        cost.toUsd() / Double(amount.value.toValue())
                    }
                }
            }
            
            func costPerServing(size: Size) -> Double {
                costPerUnit(size: size) / size.numServings
            }
            
            func costPerServingAmount(size: Size) -> Double {
                costPerServing(size: size) / size.servingSizeAmount.value.toValue()
            }
            
            func costPerEnergy(foodItem: FoodItem) -> Double? {
                let caloriesPerServing = foodItem.getNutrient(.Energy)?.value.toValue() ?? 0
                if caloriesPerServing <= 0 {
                    return nil
                }
                let totalCal = foodItem.size.numServings * caloriesPerServing
                return (costPerUnit(size: foodItem.size) / totalCal) * 100
            }
            
            func costPerWeight(size: Size) -> Double {
                try! (costPerUnit(size: size) / size.totalAmount.toGrams().value.toValue()) * 100
            }
            
            func costPerVolume(size: Size) -> Double {
                try! (costPerUnit(size: size) / size.totalAmount.toMilliliters().value.toValue()) * 100
            }
        }
        
        enum CostType: Codable, Equatable, Hashable {
            case Collection(cost: Cost, quantity: Int)
            case PerAmount(cost: Cost, amount: FoodAmount)
        }
        
        enum Cost: Codable, Equatable, Hashable {
            case Cents(_ amount: Int)
            
            func toUsd() -> Double {
                switch self {
                case .Cents(let amount):
                    return Double(amount) / 100.0
                }
            }
            
            func toString() -> String {
                let formatter: NumberFormatter = {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.maximumFractionDigits = 2
                    return formatter
                }()
                return formatter.string(for: toUsd())!
            }
            
            static func + (left: Cost, right: Cost) -> Cost {
                switch left {
                case .Cents(let l):
                    switch right {
                    case .Cents(let r):
                        return .Cents(l + r)
                    }
                }
            }
            
            static func - (left: Cost, right: Cost) -> Cost {
                switch left {
                case .Cents(let l):
                    switch right {
                    case .Cents(let r):
                        return .Cents(l - r)
                    }
                }
            }
            
            static func * (left: Cost, right: Double) -> Cost {
                switch left {
                case .Cents(let l):
                    return .Cents(Int(round(Double(l) * right)))
                }
            }
            
            static func / (left: Cost, right: Double) -> Cost {
                switch left {
                case .Cents(let l):
                    return .Cents(Int(round(Double(l) / right)))
                }
            }
        }
    }
}
