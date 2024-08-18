//
//  FoodItem.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import Foundation
import SwiftData

typealias FoodItem = SchemaV1.FoodItem
typealias FoodMetaData = SchemaV1.FoodMetaData
typealias FoodSize = SchemaV1.FoodSize

extension SchemaV1 {
    @Model
    final class FoodItem {
        // The name of the item
        var name: String
        // Any additional information about the item
        var details: String?
        // Metadata about the item
        var metaData: FoodMetaData
        // Info about the ingredients and nutrition of the item
        var ingredients: FoodIngredients
        // Info about the size of the item
        var size: FoodSize
        
        @Relationship(deleteRule: .nullify, inverse: \RecipeIngredient.food)
        var recipeEntries: [RecipeIngredient] = []
        @Relationship(deleteRule: .cascade, inverse: \StoreItem.foodItem)
        var storeItems: [StoreItem] = []
        
        init(name: String, details: String? = nil, metaData: FoodMetaData, ingredients: FoodIngredients, size: FoodSize) {
            self.name = name
            self.details = details
            self.metaData = metaData
            self.ingredients = ingredients
            self.size = size
        }
        
        func getNutrient(_ nutrient: Nutrient, numServings: Double = 1.0) -> FoodAmount? {
            if let value = ingredients.nutrients[nutrient] {
                return FoodAmount(value: value.value * numServings, unit: value.unit)
            }
            return nil
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

    struct FoodSize: Codable {
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
                numServings = totalAmount.value / value.value
            }
        }
        
        init(totalAmount: FoodAmount, numServings: Double, servingSize: String) {
            self.totalAmount = totalAmount
            self.numServings = numServings
            self.servingSize = servingSize
        }
    }
}
