//
//  FoodItem.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import Foundation
import SwiftData

typealias FoodItem = SchemaV1.FoodItem
typealias FoodComposition = SchemaV1.FoodComposition
typealias FoodMetaData = SchemaV1.FoodMetaData
typealias FoodSizeInfo = SchemaV1.FoodSizeInfo
typealias StoreInfo = SchemaV1.StoreInfo
typealias SizeType = SchemaV1.SizeType
typealias Nutrient = SchemaV1.Nutrient

extension SchemaV1 {
    @Model
    final class FoodItem {
        var name: String
        var metaData: FoodMetaData
        var composition: FoodComposition
        var sizeInfo: FoodSizeInfo
        var storeInfo: StoreInfo?
        
        init(name: String, metaData: FoodMetaData, composition: FoodComposition, sizeInfo: FoodSizeInfo, storeInfo: StoreInfo? = nil) {
            self.name = name
            self.metaData = metaData
            self.composition = composition
            self.sizeInfo = sizeInfo
            self.storeInfo = storeInfo
        }
    }
    
    struct FoodMetaData: Codable {
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
        
        init(timestamp: Date = .now, barcode: String? = nil, brand: String? = nil, icon: String? = nil, tags: [String] = []) {
            self.timestamp = timestamp
            self.barcode = barcode
            self.brand = brand
            self.icon = icon
            self.tags = tags
        }
    }

    struct FoodSizeInfo: Codable {
        // The total number of servings that the item contains
        var numServings: Double
        // Describes what the serving is
        var servingSize: String
        // The total 'size' of the item (described by sizeType)
        //  - Mass: in grams (g)
        //  - Volume: in milliliters (mL)
        var totalAmount: Double
        // The 'size' of the serving (described by sizeType)
        var servingAmount: Double
        // The type of item this is (by weight or volume)
        var sizeType: SizeType
        
        init(numServings: Double, servingSize: String, totalAmount: Double, servingAmount: Double, sizeType: SizeType) {
            self.numServings = numServings
            self.servingSize = servingSize
            self.totalAmount = totalAmount
            self.servingAmount = servingAmount
            self.sizeType = sizeType
        }
    }
    
    enum SizeType: String, CaseIterable, Codable {
        case Mass = "Mass"
        case Volume = "Volume"
    }

    struct StoreInfo: Codable {
        // The name of the store where the item was purchased from
        var name: String
        // The price of the item in its entirity (in US cents)
        var price: Int
        // If the item can still be purchased in this state
        var active: Bool
        
        init(name: String, price: Int, active: Bool = true) {
            self.name = name
            self.price = price
            self.active = active
        }
    }
    
    struct FoodComposition: Codable {
        // Stores the amount of each nutrient per serving (in mg)
        var nutrients: [Nutrient: Double]
        // The full list of ingredients that make up the item
        var ingredients: String?
        // The full list of known allergens for the item
        var allergens: String?
        
        init(nutrients: [Nutrient : Double], ingredients: String? = nil, allergens: String? = nil) {
            self.nutrients = nutrients
            self.ingredients = ingredients
            self.allergens = allergens
        }
    }
    
    enum Nutrient: Codable, Hashable {
        // Energy (Calories)
        case Energy
        // Carbs (g)
        case TotalCarbs,
             DietaryFiber,
             TotalSugars,
             AddedSugars
        // Fats (g)
        case TotalFat,
             SaturatedFat,
             TransFat,
             PolyunsaturatedFat,
             MonounsaturatedFat
        // Other (g)
        case Protein,
             Cholesterol
        // Other (mg)
        case Sodium,
             Calcium,
             VitaminD,
             Iron,
             Potassium
        
        func getUnit() -> String {
            switch self {
            case .Energy:
                return "Calories"
            case .TotalCarbs,
                    .DietaryFiber,
                    .TotalSugars,
                    .AddedSugars,
                    .TotalFat,
                    .SaturatedFat,
                    .TransFat,
                    .PolyunsaturatedFat,
                    .MonounsaturatedFat,
                    .Protein,
                    .Cholesterol:
                return "g"
            default:
                return "mg"
            }
        }
    }
}
