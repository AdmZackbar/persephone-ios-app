//
//  Recipe.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/16/24.
//

import Foundation
import SwiftData

typealias Recipe = SchemaV1.Recipe
typealias RecipeFoodEntry = SchemaV1.RecipeFoodEntry
typealias FoodUnit = SchemaV1.FoodUnit
typealias RecipeSizeInfo = SchemaV1.RecipeSizeInfo
typealias RecipeMetaData = SchemaV1.RecipeMetaData

extension SchemaV1 {
    @Model
    final class Recipe {
        var name: String
        @Relationship(deleteRule: .cascade, inverse: \RecipeFoodEntry.recipe)
        var foodEntries: [RecipeFoodEntry] = []
        var sizeInfo: RecipeSizeInfo
        var metaData: RecipeMetaData
        
        init(name: String, sizeInfo: RecipeSizeInfo, metaData: RecipeMetaData) {
            self.name = name
            self.sizeInfo = sizeInfo
            self.metaData = metaData
        }
    }
    
    @Model
    final class RecipeFoodEntry {
        var name: String
        var food: FoodItem?
        var recipe: Recipe!
        var amount: Double
        var unit: FoodUnit
        
        init(name: String, food: FoodItem? = nil, recipe: Recipe, amount: Double, unit: FoodUnit) {
            self.name = name
            self.amount = amount
            self.unit = unit
            self.food = food
            self.recipe = recipe
        }
    }
    
    enum FoodUnit: Codable {
        // Weight (US)
        case Ounce, Pound
        // Weight (SI)
        case Milligram, Gram, Kilogram
        // Volume (US)
        case Teaspoon, Tablespoon, FluidOunce, Cup, Pint, Quart, Gallon
        // Volume (SI)
        case Milliliter, Liter
        
        func isSi() -> Bool {
            return self == .Milligram || self == .Gram || self == .Kilogram || self == .Milliliter || self == .Liter
        }
        
        func getAbbreviation() -> String {
            switch self {
            case .Ounce:
                return "oz"
            case .Pound:
                return "lb"
            case .Milligram:
                return "mg"
            case .Gram:
                return "g"
            case .Kilogram:
                return "kg"
            case .Teaspoon:
                return "tsp"
            case .Tablespoon:
                return "tbsp"
            case .FluidOunce:
                return "fl oz"
            case .Cup:
                return "c"
            case .Pint:
                return "pint"
            case .Quart:
                return "qt"
            case .Gallon:
                return "gal"
            case .Milliliter:
                return "mL"
            case .Liter:
                return "L"
            }
        }
    }
    
    struct RecipeSizeInfo: Codable {
        var servingSize: String
        var numServings: Double
        var cookedWeight: Double
        
        init(servingSize: String, numServings: Double, cookedWeight: Double) {
            self.servingSize = servingSize
            self.numServings = numServings
            self.cookedWeight = cookedWeight
        }
    }
    
    struct RecipeMetaData: Codable {
        var details: String
        var instructions: String
        var totalTime: Double
        var prepTime: Double
        var cookTime: Double?
        var tags: [String]
        
        init(details: String, instructions: String, totalTime: Double, prepTime: Double, cookTime: Double? = nil, tags: [String]) {
            self.details = details
            self.instructions = instructions
            self.totalTime = totalTime
            self.prepTime = prepTime
            self.cookTime = cookTime
            self.tags = tags
        }
    }
}
