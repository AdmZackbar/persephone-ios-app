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
        var nutrients: [Nutrient : FoodAmount]
        // The full list of ingredients that make up the item
        var all: String
        // The full list of known allergens for the item
        var allergens: String
        
        init(nutrients: [Nutrient : FoodAmount], all: String = "", allergens: String = "") {
            self.nutrients = nutrients
            self.all = all
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
        case Protein
        // Other (mg)
        case Sodium,
             Cholesterol,
             Calcium,
             VitaminD,
             Iron,
             Potassium
        
        func getCommonUnit() -> FoodUnit {
            switch self {
            case .Energy:
                return .Calorie
            case .Sodium, .Cholesterol, .Calcium, .VitaminD, .Iron, .Potassium:
                return .Milligram
            default:
                return .Gram
            }
        }
    }
}
