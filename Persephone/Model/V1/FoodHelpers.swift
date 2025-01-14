//
//  FoodHelpers.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/22/24.
//

import Foundation
import SwiftData

typealias Quantity = SchemaV1.Quantity
typealias Unit = SchemaV1.Unit
typealias RatingTier = SchemaV1.RatingTier
typealias NutritionDict = [Nutrient : Quantity]

extension SchemaV1 {
    struct Quantity: Codable, Equatable, Hashable {
        // The raw value of the amount
        var value: Magnitude
        // The unit of the amount
        var unit: Unit
        
        func convert(unit: Unit) throws -> Quantity {
            if self.unit.isWeight && unit.isWeight || self.unit.isVolume && unit.isVolume {
                Quantity(value: self.value * self.unit.conversionModifier / unit.conversionModifier, unit: unit)
            } else {
                throw ParseError.invalidUnit(unitFrom: self.unit, unitTo: unit)
            }
        }
        
        enum Magnitude: Codable, Equatable, Hashable {
            case Raw(_ value: Double)
            case Rational(num: Double, den: Double)
            
            var value: Double {
                get {
                    switch self {
                    case .Raw(let value):
                        return value
                    case .Rational(let num, let den):
                        return num / den
                    }
                }
            }
        }
    }
    
    enum Unit: Codable, Equatable, Hashable {
        // Energy
        case Calorie
        // Weight (US)
        case Ounce, Pound
        // Weight (SI)
        case Microgram, Milligram, Gram, Kilogram
        // Volume (US)
        case Teaspoon, Tablespoon, FluidOunce, Cup, Pint, Quart, Gallon
        // Volume (SI)
        case Milliliter, Liter
        // Other
        case Serving
        case Custom(name: String)
        
        var isSi: Bool {
            get {
                switch self {
                case .Microgram, .Milligram, .Gram, .Kilogram, .Milliliter, .Liter:
                    true
                default:
                    false
                }
            }
        }
        
        var isWeight: Bool {
            switch self {
            case .Ounce, .Pound, .Microgram, .Milligram, .Gram, .Kilogram:
                return true
            default:
                return false
            }
        }
        
        var isVolume: Bool {
            switch self {
            case .Milliliter, .Liter, .Teaspoon, .Tablespoon, .FluidOunce, .Cup, .Pint, .Quart, .Gallon:
                return true
            default:
                return false
            }
        }
        
        var abbreviation: String {
            switch self {
            case .Calorie:
                ""
            case .Ounce:
                "oz"
            case .Pound:
                "lb"
            case .Microgram:
                "mcg"
            case .Milligram:
                "mg"
            case .Gram:
                "g"
            case .Kilogram:
                "kg"
            case .Teaspoon:
                "tsp"
            case .Tablespoon:
                "tbsp"
            case .FluidOunce:
                "fl oz"
            case .Cup:
                "c"
            case .Pint:
                "pint"
            case .Quart:
                "qt"
            case .Gallon:
                "gal"
            case .Milliliter:
                "mL"
            case .Liter:
                "L"
            case .Serving:
                "serving"
            case .Custom(let name):
                name
            }
        }
        
        var conversionModifier: Double {
            switch self {
            // Weight
            case .Microgram:
                0.001
            case .Milligram:
                1
            case .Gram:
                1000
            case .Kilogram:
                1000000
            case .Ounce:
                28349.5
            case .Pound:
                453592
            // Volume
            case .Milliliter:
                1
            case .Liter:
                1000
            case .Teaspoon:
                4.92892
            case .Tablespoon:
                14.7868
            case .FluidOunce:
                29.5735
            case .Cup:
                240
            case .Pint:
                473.176
            case .Quart:
                946.353
            case .Gallon:
                3785.41
            default:
                1
            }
        }
    }
    
    enum ParseError: Error {
        case invalidUnit(unitFrom: Unit, unitTo: Unit)
    }
    
    enum RatingTier: String, CaseIterable, Codable, Identifiable {
        var id: String {
            get {
                rawValue
            }
        }
        
        case S, A, B, C, D, F
        
        var rating: Double {
            switch self {
            case .S:
                9.5
            case .A:
                8
            case .B:
                6.5
            case .C:
                5
            case .D:
                3.5
            case .F:
                1
            }
        }
        
        static func fromRating(rating: Double?) -> RatingTier? {
            if rating == nil {
                return nil
            }
            let rating = rating!
            if rating >= 9 {
                return .S
            }
            if rating >= 7.5 {
                return .A
            }
            if rating >= 6 {
                return .B
            }
            if rating >= 4.5 {
                return .C
            }
            if rating >= 3 {
                return .D
            }
            return .F
        }
    }
}
