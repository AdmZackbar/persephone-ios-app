//
//  Food.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/22/24.
//

import Foundation

typealias FoodAmount = SchemaV1.FoodAmount
typealias FoodUnit = SchemaV1.FoodUnit

extension SchemaV1 {
    struct FoodAmount: Codable, Equatable, Hashable {
        static func calories(_ value: Double) -> FoodAmount {
            FoodAmount(value: value, unit: .Calorie)
        }
        
        static func grams(_ value: Double) -> FoodAmount {
            FoodAmount(value: value, unit: .Gram)
        }
        
        static func milligrams(_ value: Double) -> FoodAmount {
            FoodAmount(value: value, unit: .Milligram)
        }
        
        // The raw value of the amount
        var value: Double
        // The unit of the amount
        var unit: FoodUnit
        
        func toMilligrams() throws -> FoodAmount {
            var modifier: Double!
            switch unit {
            case .Milligram:
                modifier = 1
                break
            case .Gram:
                modifier = 1000
                break
            case .Kilogram:
                modifier = 1000000
                break
            case .Ounce:
                modifier = 28349.5
                break
            case .Pound:
                modifier = 453592
                break
            default:
                throw FoodError.invalidUnit(unit: unit)
            }
            return FoodAmount(value: value * modifier, unit: .Milligram)
        }
    }
    
    enum FoodUnit: Codable, CaseIterable, Equatable, Hashable {
        // Energy
        case Calorie
        // Weight (US)
        case Ounce, Pound
        // Weight (SI)
        case Milligram, Gram, Kilogram
        // Volume (US)
        case Teaspoon, Tablespoon, FluidOunce, Cup, Pint, Quart, Gallon
        // Volume (SI)
        case Milliliter, Liter
        
        func isSi() -> Bool {
            switch self {
            case .Milligram, .Gram, .Kilogram, .Milliliter, .Liter:
                return true
            default:
                return false
            }
        }
        
        func isWeight() -> Bool {
            switch self {
            case .Ounce, .Pound, .Milligram, .Gram, .Kilogram:
                return true
            default:
                return false
            }
        }
        
        func getAbbreviation() -> String {
            switch self {
            case .Calorie:
                return ""
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
    
    enum FoodError: Error {
        case invalidUnit(unit: FoodUnit)
    }
}
