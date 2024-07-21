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
typealias RecipeInstructions = SchemaV1.RecipeInstructions
typealias RecipeSection = SchemaV1.RecipeSection

extension SchemaV1 {
    @Model
    final class Recipe {
        var name: String
        @Relationship(deleteRule: .cascade, inverse: \RecipeFoodEntry.recipe)
        var foodEntries: [RecipeFoodEntry] = []
        var sizeInfo: RecipeSizeInfo
        var metaData: RecipeMetaData
        var composition: FoodComposition?
        
        init(name: String, sizeInfo: RecipeSizeInfo, metaData: RecipeMetaData, composition: FoodComposition? = nil) {
            self.name = name
            self.sizeInfo = sizeInfo
            self.metaData = metaData
            self.composition = composition
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
    
    enum FoodUnit: Codable, CaseIterable {
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
        
        func getNames() -> [String] {
            switch self {
            case .Ounce:
                return ["oz", "ounce", "ounces"]
            case .Pound:
                return ["lb", "lbs", "pound", "pounds"]
            case .Milligram:
                return ["mg", "milligram", "milligrams"]
            case .Gram:
                return ["g", "gram", "grams"]
            case .Kilogram:
                return ["kg", "kilogram", "kilograms"]
            case .Teaspoon:
                return ["tsp", "teaspoon", "teaspoons"]
            case .Tablespoon:
                return ["tbsp", "tablespoon", "tablespoons"]
            case .FluidOunce:
                return ["fl oz", "fluid ounce", "fluid ounces"]
            case .Cup:
                return ["c", "cup", "cups"]
            case .Pint:
                return ["pint", "pints"]
            case .Quart:
                return ["qt", "quart", "quarts"]
            case .Gallon:
                return ["gal", "gallon", "gallons"]
            case .Milliliter:
                return ["mL", "milliliter", "milliliters"]
            case .Liter:
                return ["L", "liter", "liters"]
            }
        }
    }
    
    struct RecipeSizeInfo: Codable {
        var servingSize: String
        var numServings: Double
        var cookedWeight: Double?
        
        init(servingSize: String, numServings: Double, cookedWeight: Double? = nil) {
            self.servingSize = servingSize
            self.numServings = numServings
            self.cookedWeight = cookedWeight
        }
    }
    
    struct RecipeMetaData: Codable {
        var details: String
        var instructions: RecipeInstructions
        var prepTime: Double
        var cookTime: Double
        var totalTime: Double {
            get {
                prepTime + cookTime
            }
        }
        var tags: [String]
        
        init(details: String, instructions: RecipeInstructions, prepTime: Double, cookTime: Double, tags: [String]) {
            self.details = details
            self.instructions = instructions
            self.prepTime = prepTime
            self.cookTime = cookTime
            self.tags = tags
        }
    }
    
    struct RecipeInstructions: Codable {
        var sections: [RecipeSection]
        
        init(sections: [RecipeSection]) {
            self.sections = sections
        }
    }
    
    struct RecipeSection: Codable, Equatable, Hashable {
        var header: String?
        var steps: [String]
        
        init(header: String? = nil, steps: [String] = []) {
            self.header = header
            self.steps = steps
        }
    }
}
