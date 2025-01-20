//
//  Nutrients.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/22/24.
//

import Foundation
import SwiftData

typealias Nutrients = [Nutrient : Double]

extension Nutrients {
    var calories: Amount {
        return .init(value: .raw(self[.Energy, default: 0]), unit: Units.calorie)
    }
    
    func get(_ nutrient: Nutrient) -> Amount? {
        if let value = self[nutrient] {
            return .init(value: .raw(value), unit: nutrient.getCommonUnit())
        }
        return nil
    }
    
    static prefix func - (x: Nutrients) -> Nutrients {
        x.mapValues({ -$0 })
    }
    
    static func + (lhs: Nutrients, rhs: Nutrients) -> Nutrients {
        lhs.merging(rhs, uniquingKeysWith: +)
    }
    
    static func - (lhs: Nutrients, rhs: Nutrients) -> Nutrients {
        lhs.merging(rhs, uniquingKeysWith: -)
    }
    
    static func * (lhs: Nutrients, rhs: Double) -> Nutrients {
        lhs.mapValues({ $0 * rhs })
    }
    
    static func / (lhs: Nutrients, rhs: Double) -> Nutrients {
        lhs.mapValues({ $0 / rhs })
    }
}

struct FoodIngredients: Codable, Equatable, Hashable {
    // Stores the amount of each nutrient per serving
    var nutrients: Nutrients = [:]
    // The full list of ingredients that make up the item
    var all: String = ""
    // The full list of known allergens for the item
    var allergens: String = ""
    
    init(nutrients: Nutrients = [:],
         all: String = "",
         allergens: String = "") {
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
    
    func getCommonUnit() -> Amount.Unit {
        switch self {
        case .Energy:
            return Units.calorie
        case .Sodium, .Cholesterol, .Calcium, .Iron, .Potassium:
            return Units.milligram
        case .VitaminD:
            return Units.microgram
        default:
            return Units.gram
        }
    }
}
