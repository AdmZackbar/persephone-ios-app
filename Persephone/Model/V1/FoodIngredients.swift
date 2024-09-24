//
//  FoodIngredients.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/22/24.
//

import Foundation
import SwiftData

typealias FoodIngredients = SchemaV1.FoodIngredients
typealias Nutrient = SchemaV1.Nutrient

extension SchemaV1 {
    struct FoodIngredients: Codable {
        // Stores the amount of each nutrient per serving
        var nutrients: NutritionDict
        // The full list of ingredients that make up the item
        var all: String
        // The full list of known allergens for the item
        var allergens: String
        
        init(nutrients: NutritionDict, all: String = "", allergens: String = "") {
            self.nutrients = nutrients
            self.all = all
            self.allergens = allergens
        }
    }
    
    enum Nutrient: Codable, Equatable, Hashable {
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
        // Other
        case Protein,
             Sodium,
             Cholesterol,
             Calcium,
             VitaminD,
             Iron,
             Potassium
        
        func getCommonUnit() -> Unit {
            switch self {
            case .Energy:
                return .Calorie
            case .Sodium, .Cholesterol, .Calcium, .Iron, .Potassium:
                return .Milligram
            case .VitaminD:
                return .Microgram
            default:
                return .Gram
            }
        }
    }
}
